# Contributing to Vision Centre Mapping - Backend

Thank you for contributing to the backend configurations and administration repository.

## 🛠️ Contribution Guidelines

1.  **Repository Forking**: Fork the repository and check out a working branch locally.
2.  **Schema Updates**: If modifying database structures:
    *   Update the schema documentation in `docs/database_schema.md`.
    *   Provide updated templates in `samples/centers_sample.csv`.
3.  **Firebase Rules Changes**: 
    *   Do not commit active production credentials or secrets.
    *   Test safety boundaries on rules templates using the Firebase emulator suite before proposing alterations.
4.  **Committing code**: Stage your files and use meaningful git comments:
    ```bash
    git add .
    git commit -m "feat(rules): restrict delete permission to admin role"
    ```
5.  **Submit PR**: Open a pull request against the `main` branch.

## 🔒 Security Review

All updates affecting `firebase/firestore.rules` or credential variables must undergo security checks to confirm no database leak vectors are introduced.
