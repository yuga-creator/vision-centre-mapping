# Contributing to Vision Centre Mapping - Frontend

We welcome contributions from Appasamy Associates and the community! To ensure a smooth process, please follow the guidelines below.

## 🛠️ Development Workflow

1.  **Fork the Repository**: Create a personal copy of the repository on GitHub.
2.  **Clone Locally**:
    ```bash
    git clone https://github.com/<your-org>/vision-centre-mapping-frontend.git
    cd vision-centre-mapping-frontend
    ```
3.  **Create a Branch**: Create a feature or bugfix branch:
    ```bash
    git checkout -b feature/your-feature-name
    ```
4.  **Implement Changes**: Make your changes. Ensure code style is consistent and clean.
5.  **Run Tests**: Run flutter analyzer and verify tests:
    ```bash
    flutter analyze
    flutter test
    ```
6.  **Commit and Push**:
    ```bash
    git add .
    git commit -m "feat(map): add new overlay layer"
    git push origin feature/your-feature-name
    ```
7.  **Submit a Pull Request (PR)**: Open a PR on GitHub comparing your feature branch against `main`.

## 🎨 Coding Standards

*   Follow standard Dart formatting rules: Run `dart format .` before committing.
*   Ensure that no sensitive files (like `google-services.json` or `.env`) are committed.
*   Use meaningful commit messages following [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## 🐛 Reporting Issues

If you find a bug or have a suggestion, please open an issue in the GitHub tracker containing:
*   A clear description of the bug.
*   Steps to reproduce the bug.
*   Expected and actual results.
*   Flutter doctor details (`flutter doctor -v`).
