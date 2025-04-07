# Ortak Expense Sharing App

A Flutter application for tracking and splitting group expenses.

## Project Structure

The project follows a feature-first architecture with clean separation of concerns:

```
lib/
├── app.dart                  # Main app configuration
├── main.dart                 # Entry point
├── core/                     # Application core
│   ├── config/               # App configuration
│   ├── database/             # Database setup and helpers
│   ├── theme/                # Theme configuration
│   └── utils/                # Utility functions
├── features/                 # Feature modules
│   ├── auth/                 # Authentication feature
│   │   ├── presentation/     # UI components
│   │   │   ├── components/   # Reusable UI elements
│   │   │   └── screens/      # Screen widgets
│   │   ├── providers/        # State management
│   │   └── repositories/     # Data access
│   ├── expenses/             # Expenses feature
│   │   ├── presentation/
│   │   │   ├── components/   # Reusable UI elements
│   │   │   └── screens/      # Screen widgets
│   │   └── providers/        # State management
│   ├── groups/               # Groups feature
│   │   ├── presentation/
│   │   │   ├── components/   # Reusable UI elements
│   │   │   └── screens/      # Screen widgets
│   │   └── providers/        # State management
│   └── home/                 # Home screens
└── shared/                   # Shared resources
    ├── models/               # Data models
    ├── providers/            # Shared providers
    └── widgets/              # Common widgets
```

## Architecture

- **Feature-first**: Code is organized by features to improve maintainability
- **Clean Architecture**: Separation between UI, business logic, and data access
- **Riverpod**: Used for state management across the app
- **SQLite**: Used for local data persistence with `sqflite`

## Key Components

### Core
- **DatabaseHelper**: Central database management
- **ThemeData**: App-wide theme configuration
- **Utils**: Utility functions for common operations

### Features
Each feature follows a similar structure:
- **Presentation**: UI components (screens and reusable components)
- **Providers**: State management using Riverpod
- **Repositories**: Data access layer

### Shared
- **Models**: Data classes shared across features
- **Widgets**: Reusable widgets used throughout the app

## Usage

This app allows users to:
- Create and manage groups
- Add members to groups
- Create and track expenses within groups
- Split expenses between group members
- View balances and settle debts

## Features

- User Authentication
- Group Management
- Expense Tracking
- Debt Calculation
- Profile Management

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ortak.git
cd ortak
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Dependencies

Main dependencies:
- flutter_riverpod: State management
- sqflite: Local database
- path: File system paths
- uuid: Unique identifiers

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
