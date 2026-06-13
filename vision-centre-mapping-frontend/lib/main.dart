import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http; 
import 'package:firebase_core/firebase_core.dart';
import 'firestore_helper.dart'; 
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}

// --- 1. REUSABLE GLASS WIDGET ---
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const GlassCard({
    super.key, 
    required this.child, 
    this.borderRadius = 20, 
    this.padding, 
    this.margin,
    this.onTap,
    this.backgroundColor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: backgroundColor ?? Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. HOME SCREEN
// -----------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final Distance _distanceCalculator = const Distance();
  
  late AnimationController _animController;
  List<dynamic> _centers = [];
  bool _isLoading = false;
  
  // --- ADMIN SETTINGS ---
  bool _isAdmin = false; 
  final String _adminPassword = "admin"; 

  double _selectedRangeKm = 50.0;
  final List<double> _rangeOptions = [5.0, 10.0, 20.0, 50.0, 100.0];
  LatLng? _userLocation; 

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _getCurrentLocation(); 
  }

  @override
  void dispose() {
    _animController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      
      if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
        Position pos = await Geolocator.getCurrentPosition();
        setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
        
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (placemarks.isNotEmpty && placemarks.first.postalCode != null) {
            _pinController.text = placemarks.first.postalCode!;
            _showSnack("📍 Located: ${placemarks.first.locality}", Colors.green.shade700);
            await _search(); 
          } else {
             await _search();
          }
        } catch (e) { 
           _showSnack("GPS set.", Colors.blue);
           await _search();
        }
      }
    } catch (e) {
      _showSnack("GPS Error: $e", Colors.red);
      await _search();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ADMIN LOGIN DIALOG ---
  void _showAdminLogin() {
    TextEditingController passCtrl = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Admin Login"),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Enter Password"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (passCtrl.text == _adminPassword) {
                setState(() => _isAdmin = true);
                Navigator.pop(ctx);
                _showSnack("🔓 Admin Mode Unlocked", Colors.green);
              } else {
                _showSnack("❌ Wrong Password", Colors.red);
              }
            },
            child: const Text("Login"),
          )
        ],
      )
    );
  }

  Future<void> _search() async {
    setState(() { _isLoading = true; _centers = []; });
    _animController.reset();
    try {
      List<Map<String, dynamic>> allCenters = await FirestoreHelper.instance.getAllCenters();
      List<dynamic> centersList = List.from(allCenters);
      List<dynamic> filtered = [];
      String pin = _pinController.text.trim().replaceAll(" ", "");
      LatLng? anchorLocation;

      if (pin.isNotEmpty) {
        try {
          List<Location> locs = await locationFromAddress("postal code $pin, India");
          if (locs.isNotEmpty) anchorLocation = LatLng(locs.first.latitude, locs.first.longitude);
        } catch (e) {
           try {
             List<Location> locs = await locationFromAddress(pin);
             if (locs.isNotEmpty) anchorLocation = LatLng(locs.first.latitude, locs.first.longitude);
           } catch (e2) {}
        }
      }
      if (anchorLocation == null && _userLocation != null) anchorLocation = _userLocation;

      if (anchorLocation != null) {
        for (var i = 0; i < centersList.length; i++) {
          var center = Map<String, dynamic>.from(centersList[i]);
          double lat = double.tryParse(center['latitude'].toString()) ?? 0;
          double lng = double.tryParse(center['longitude'].toString()) ?? 0;
          
          if (lat != 0 && lng != 0) {
            double dist = _distanceCalculator.as(LengthUnit.Meter, anchorLocation, LatLng(lat, lng)) / 1000;
            center['distance_km'] = dist;
            if (dist <= _selectedRangeKm) filtered.add(center);
          }
        }
        filtered.sort((a, b) => (a['distance_km'] as double).compareTo(b['distance_km'] as double));
      } else {
        filtered = centersList;
      }
      
      if (filtered.length > 50) filtered = filtered.sublist(0, 50);
      setState(() => _centers = filtered);
      if (_centers.isNotEmpty) _animController.forward();
    } catch (e) { _showSnack("Error: $e", Colors.red); } 
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)], begin: Alignment.topLeft, end: Alignment.bottomRight)
        ),
        child: Stack(
          children: [
            Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.2)))),
            
            SafeArea(
              child: Column(
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("Vision 2020", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                          Text("Locate your Nearest Eye Care Centre :)", style: TextStyle(color: Colors.black54, fontSize: 14)),
                        ]),
                        
                        Row(
                          children: [
                            GlassCard(
                              padding: const EdgeInsets.all(10),
                              borderRadius: 14,
                              onTap: _isAdmin 
                                ? () => setState(() { _isAdmin = false; _showSnack("🔒 Admin Mode Locked", Colors.orange); })
                                : _showAdminLogin,
                              child: Icon(
                                _isAdmin ? Icons.lock_open_rounded : Icons.lock_rounded, 
                                color: _isAdmin ? Colors.green : Colors.grey
                              ),
                            ),
                            const SizedBox(width: 8),
                            GlassCard(
                              padding: const EdgeInsets.all(10),
                              borderRadius: 14,
                              onTap: () { _pinController.clear(); _search(); },
                              child: const Icon(Icons.refresh_rounded, color: Color(0xFF1E3A8A)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  // ADMIN PANEL
                  if (_isAdmin)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCentreScreen()));
                            if (result == true) {
                              _pinController.clear();
                              _search(); 
                            }
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text("Add New Centre", style: TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                          ),
                        ),
                      ),
                    ),

                  // SEARCH & GPS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: GlassCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Colors.grey, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _pinController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(hintText: "Enter PIN Code...", border: InputBorder.none),
                              onSubmitted: (_) => _search(),
                            ),
                          ),
                          IconButton(
                            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location_rounded, color: Color(0xFF1E3A8A)),
                            onPressed: _getCurrentLocation,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // RADIUS
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: _rangeOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        double radius = _rangeOptions[index];
                        bool isSelected = _selectedRangeKm == radius;
                        return GestureDetector(
                          onTap: () { setState(() => _selectedRangeKm = radius); _search(); },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E3A8A) : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.6)),
                            ),
                            child: Center(child: Text("${radius.toInt()} km", style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))),
                          ),
                        );
                      },
                    ),
                  ),

                  // LIST
                  Expanded(
                    child: _centers.isEmpty 
                      ? Center(child: Text("No centers found.", style: TextStyle(color: Colors.black45, fontSize: 16)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          itemCount: _centers.length,
                          itemBuilder: (ctx, index) {
                            var center = _centers[index];
                            double lat = double.tryParse(center['latitude'].toString()) ?? 0;
                            double lng = double.tryParse(center['longitude'].toString()) ?? 0;
                            double? dist = center['distance_km'];
                            
                            return FadeTransition(
                              opacity: _animController,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(0),
                                  onTap: () async {
                                    if (_userLocation != null && lat != 0) {
                                      final result = await Navigator.push(
                                        context, 
                                        MaterialPageRoute(builder: (_) => CinematicMapScreen(center: center, userLocation: _userLocation!, isAdmin: _isAdmin))
                                      );
                                      if (result == true) {
                                        _search();
                                      }
                                    } else {
                                      _showSnack("Need GPS location to view map route", Colors.orange);
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      Hero(
                                        tag: "map_${center['id'] ?? index}", 
                                        child: SizedBox(
                                          height: 120,
                                          width: double.infinity,
                                          child: IgnorePointer( 
                                            child: FlutterMap(
                                              // OPTIMIZED MAP HERE:
                                              options: MapOptions(
                                                initialCenter: LatLng(lat, lng), 
                                                initialZoom: 13, 
                                                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)
                                              ),
                                              children: [
                                                TileLayer(
                                                  // OPTIMIZED TILE PROVIDER AND URL
                                                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                                                  subdomains: const ['a', 'b', 'c', 'd'],
                                                  tileProvider: CancellableNetworkTileProvider(),
                                                  userAgentPackageName: 'com.example.eye_app',
                                                ),
                                                MarkerLayer(markers: [Marker(point: LatLng(lat, lng), width: 30, height: 30, child: const Icon(Icons.location_on, color: Colors.redAccent, size: 30))])
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(center['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                  if (dist != null) Text("${dist.toStringAsFixed(1)} km away", style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w700)),
                                                  Text(center['address'] ?? "", style: TextStyle(color: Colors.black54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. CINEMATIC MAP SCREEN (Details & Delete)
// -----------------------------------------------------------------------------
class CinematicMapScreen extends StatefulWidget {
  final dynamic center;
  final LatLng userLocation;
  final bool isAdmin; 

  const CinematicMapScreen({
    super.key, 
    required this.center, 
    required this.userLocation,
    this.isAdmin = false 
  });

  @override
  State<CinematicMapScreen> createState() => _CinematicMapScreenState();
}

class _CinematicMapScreenState extends State<CinematicMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  late AnimationController _routeAnimController;
  late AnimationController _cardAnimController;
  bool _isDeleting = false;
  
  String? _getPhoneNumber() {
    var c = widget.center;
    if (c['phone_num'] != null) return c['phone_num'].toString();
    if (c['contact_number'] != null) return c['contact_number'].toString();
    if (c['Phone Number'] != null) return c['Phone Number'].toString();
    if (c['Phone Number '] != null) return c['Phone Number '].toString();
    if (c['phone'] != null) return c['phone'].toString();
    return null;
  }

  @override
  void initState() {
    super.initState();
    _routeAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _cardAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fetchRoute();
  }

  @override
  void dispose() {
    _routeAnimController.dispose();
    _cardAnimController.dispose();
    super.dispose();
  }

  Future<void> _deleteCentre() async {
    bool? confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Centre?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        String id = widget.center['id'].toString();
        await FirestoreHelper.instance.deleteCenter(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Centre Deleted"), backgroundColor: Colors.red));
          Navigator.pop(context, true); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  Future<void> _fetchRoute() async {
    try {
      double startLat = widget.userLocation.latitude;
      double startLng = widget.userLocation.longitude;
      double endLat = double.tryParse(widget.center['latitude'].toString()) ?? 0;
      double endLng = double.tryParse(widget.center['longitude'].toString()) ?? 0;

      if (endLat == 0 || endLng == 0) return; 

      final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
           final geometry = data['routes'][0]['geometry']['coordinates'] as List;
           setState(() {
             _routePoints = geometry.map((p) => LatLng(p[1], p[0])).toList();
           });
           
           _routeAnimController.forward();
           Future.delayed(const Duration(milliseconds: 500), () => _cardAnimController.forward());
        } else {
           _cardAnimController.forward();
        }
      }
    } catch (e) {
      debugPrint("Route error: $e");
      _cardAnimController.forward();
    }
  }

  Future<void> _launchMaps() async {
    String address = widget.center['address'] ?? "";
    if (address.isEmpty) return;
    final encoded = Uri.encodeComponent(address);
    final url = Uri.parse("google.navigation:q=$encoded");
    if (!await launchUrl(url)) await launchUrl(Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$encoded"), mode: LaunchMode.externalApplication);
  }

  Future<void> _launchDialer() async {
    String? phone = _getPhoneNumber();
    if (phone == null) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(Uri.parse("tel:$clean"));
  }

  @override
  Widget build(BuildContext context) {
    double destLat = double.tryParse(widget.center['latitude'].toString()) ?? 0;
    double destLng = double.tryParse(widget.center['longitude'].toString()) ?? 0;
    String name = widget.center['name'] ?? "Unknown";
    String address = widget.center['address'] ?? "";
    String type = widget.center['centre_type'] ?? "Center";
    String partner = widget.center['partner_name'] ?? "";
    String baseHospital = widget.center['base_hospital'] ?? "";

    return Scaffold(
      body: Stack(
        children: [
          Hero(
            tag: "map_${widget.center['id'] ?? 0}",
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng((widget.userLocation.latitude + destLat)/2, (widget.userLocation.longitude + destLng)/2), 
                initialZoom: 11.0
              ),
              children: [
                TileLayer(
                  // OPTIMIZED TILE PROVIDER AND URL
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  tileProvider: CancellableNetworkTileProvider(),
                  userAgentPackageName: 'com.example.eye_app',
                ),
                
                if (_routePoints.isNotEmpty)
                  AnimatedBuilder(
                    animation: _routeAnimController,
                    builder: (context, child) {
                      int count = (_routePoints.length * _routeAnimController.value).toInt();
                      List<LatLng> visiblePoints = _routePoints.sublist(0, count);
                      return PolylineLayer(
                        polylines: [Polyline(points: visiblePoints, strokeWidth: 5.0, color: const Color(0xFF6366F1))],
                      );
                    },
                  ),

                MarkerLayer(markers: [
                  Marker(point: widget.userLocation, width: 25, height: 25, child: Container(decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(blurRadius: 5)]))),
                  Marker(point: LatLng(destLat, destLng), width: 50, height: 50, child: const Icon(Icons.location_on, color: Colors.redAccent, size: 50))
                ]),
              ],
            ),
          ),

          Positioned(
            top: 50, left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOutBack)),
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 30, offset: const Offset(0, 10))],
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(type, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.1)),
                    const SizedBox(height: 10),
                    if (partner.isNotEmpty) 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text("Partner: $partner", style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    if (baseHospital.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text("Base Hospital: $baseHospital", style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    Text(address, style: const TextStyle(color: Colors.black54, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _launchDialer,
                            icon: const Icon(Icons.call, color: Colors.white),
                            label: const Text("Call Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _launchMaps,
                            icon: const Icon(Icons.directions, color: Colors.white),
                            label: const Text("Navigate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          ),
                        ),
                      ],
                    ),
                    
                    if (widget.isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isDeleting ? null : _deleteCentre,
                            icon: _isDeleting 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                              : const Icon(Icons.delete, color: Colors.red),
                            label: const Text("Remove Centre", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                            ),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. ADD CENTRE SCREEN
// -----------------------------------------------------------------------------
class AddCentreScreen extends StatefulWidget {
  const AddCentreScreen({super.key});

  @override
  State<AddCentreScreen> createState() => _AddCentreScreenState();
}

class _AddCentreScreenState extends State<AddCentreScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _typeController = TextEditingController(); 
  
  final TextEditingController _partnerController = TextEditingController();
  final TextEditingController _baseHospitalController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveCentre() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      double lat = 0.0;
      double lng = 0.0;
      try {
        List<Location> locations = await locationFromAddress("${_addressController.text}, India");
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not find address on map. Check spelling or add PIN code."), backgroundColor: Colors.orange),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      Map<String, dynamic> newCentre = {
        'name': _nameController.text,
        'address': _addressController.text,
        'contact_number': _phoneController.text, 
        'centre_type': _typeController.text.isEmpty ? 'Eye Centre' : _typeController.text,
        'latitude': lat,
        'longitude': lng,
        'partner_name': _partnerController.text, 
        'base_hospital': _baseHospitalController.text
      };

      await FirestoreHelper.instance.insertCenter(newCentre);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Centre Added Successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildGlassInput(String hint, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GlassCard(
        borderRadius: 15,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
          validator: (val) => val == null || val.isEmpty ? "Required" : null,
          decoration: InputDecoration(
            icon: Icon(icon, color: Colors.grey),
            border: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Stack(
          children: [
            Positioned(top: -50, left: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.15)))),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        GlassCard(
                          borderRadius: 12,
                          onTap: () => Navigator.pop(context),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
                        ),
                        const SizedBox(width: 15),
                        const Text("Add New Centre", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildGlassInput("Centre Name", _nameController, Icons.local_hospital_rounded),
                            _buildGlassInput("Address (Include City/Pin)", _addressController, Icons.location_on_rounded),
                            _buildGlassInput("Phone Number", _phoneController, Icons.phone_rounded, isNumber: true),
                            _buildGlassInput("Type (e.g. Clinic, Hospital)", _typeController, Icons.category_rounded),
                            
                            _buildGlassInput("Partner Name", _partnerController, Icons.handshake_rounded),
                            _buildGlassInput("Base Hospital", _baseHospitalController, Icons.local_hospital_outlined),

                            const SizedBox(height: 20),
                            
                            GestureDetector(
                              onTap: _isSaving ? null : _saveCentre,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                                ),
                                child: Center(
                                  child: _isSaving 
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text("SAVE CENTRE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// -----------------------------------------------------------------------------
// 5. SPLASH SCREEN (GIF LOADER)
// -----------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 4 seconds (or however long your GIF is)
    Future.delayed(const Duration(seconds: 4), () {
      // Use pushReplacement so the user can't go "back" to the splash screen
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const HomeScreen())
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Same gradient as Home for smooth feel
          gradient: LinearGradient(
            colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)], 
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // YOUR GIF HERE
            Image.asset(
              'assets/splash.gif',
              height: 200, // Adjust size as needed
              width: 200,
            ),
            const SizedBox(height: 20),
            // Optional: Text under the GIF
            const Text(
              "Vision 2020",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.w900, 
                color: Color(0xFF1E3A8A),
                letterSpacing: 1.5
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Loading Maps...",
              style: TextStyle(color: Colors.black45, fontSize: 14),
            )
          ],
        ),
      ),
    );
  }
}