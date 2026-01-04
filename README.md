# Aurora

A beautiful iOS productivity app built with SwiftUI for iOS 26+, featuring liquid glass design aesthetics.

## Features

- **Task Management** — Create, organize, and track tasks with categories, priorities, and due dates
- **Journal** — Personal journaling with mood tracking and rich text support
- **Calendar** — Visual calendar integration for planning and scheduling
- **Smart Lists** — Intelligent task filtering (Today, Scheduled, Flagged, etc.)
- **Customization** — Personalize your experience with themes and layouts

## Requirements

- iOS 26.0+
- Xcode 16.0+
- Swift 6.2+

## Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/souhailtajir/git-Aurora.git
   ```

2. Open `Aurora.xcodeproj` in Xcode

3. Build and run on a simulator or device

## Architecture

Aurora follows a modern SwiftUI architecture with:

- **SwiftUI Views** — Declarative UI with liquid glass effects
- **Observable State** — `@Observable` classes for reactive data flow
- **SwiftData** — Native persistence layer

## Project Structure

```
Aurora/
├── Aurora/                 # Main app source
│   ├── Views/             # SwiftUI views
│   ├── Models/            # Data models
│   ├── Stores/            # State management
│   └── Components/        # Reusable UI components
├── AuroraTests/           # Unit tests
└── AuroraUITests/         # UI tests
```

## License

This project is proprietary. All rights reserved.

---

_Built with ❤️ using SwiftUI_
