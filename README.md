# SQLite4D

[![](https://img.shields.io/github/v/release/TheCodeNaked/SQLite4D)](https://github.com/TheCodeNaked/SQLite4D/releases)

![Delphi](https://img.shields.io/badge/language-Delphi-orange)

**A lightweight declarative persistence engine for SQLite using Delphi.**

SQLite4D was created to solve — in a fluent, safe and reusable way — the main challenges of using SQLite in Delphi applications, especially in mobile or offline scenarios.

> 🔧 **Create, alter and manage SQLite tables at runtime with clarity and full control.**

---

## 🚀 Main Features

- Create SQLite tables automatically from `TFDMemTable`
- Batch insertions with progress callback
- Full transactional control
- Safe schema evolution using structured operations
- Fluent interfaces (`IFieldConfigurator`, `ITableDefinition`, etc.)
- Compatible with FireDAC and cross-platform Delphi (FMX/VCL)
- Supports `ALTER TABLE` operations (via rebuild strategy)

---

## 🧪 Quick Example

```pascal
LSQLite4D := TSQLite4D.GetInstance('mydb.db');

LSQLite4D.CreateSQLiteTableFromMemTable(MemTable, 'Customers', False);

LSQLite4D.CopyDataFromMemTableToSQLite('Customers', MemTable, 1,
  procedure(Progress: Integer)
  begin
    // callback for progress
  end);
```

---

## 🧩 Highlight: `ExecuteMultipleSQL`

This method implements the recommended pattern for advanced schema changes in SQLite, such as renaming columns or modifying constraints — actions that are not directly supported by SQLite's native `ALTER TABLE`.

```pascal
LSQLite4D.ExecuteMultipleSQL([
  'PRAGMA foreign_keys=OFF;',
  'CREATE TEMP TABLE Users_backup AS SELECT * FROM Users;',
  'DROP TABLE Users;',
  'CREATE TABLE Users (...new schema...);',
  'INSERT INTO Users SELECT * FROM Users_backup;',
  'DROP TABLE Users_backup;',
  'PRAGMA foreign_keys=ON;'
]);
```

All within a transaction. If anything fails, no changes are committed.

---

## 📂 Project Structure

- `/src`: Core unit(s) of SQLite4D
- `/examples`: Full demo project using `TFDMemTable` and SQLite4D
- `/docs`: (Optional) Posts, internal notes, changelogs, etc.

---

## 📝 License

MIT — Free to use, modify and distribute in commercial or open-source projects.

---

## 📣 About the Project

Developed by [TheCodeNaked](https://github.com/TheCodeNaked), an initiative that believes code should be expressive, elegant, and grounded in real problem-solving — not unnecessary complexity.
