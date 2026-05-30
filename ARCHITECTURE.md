# Rift - Architecture Documentation

## 📋 Overview

Rift is a next-generation NoSQL database for Flutter & Dart. It's a pure Dart implementation with zero native dependencies, providing blazing fast performance, reactive queries, and advanced features.

## 🏗️ Project Structure

### Core Packages

```
rift/
├── rift/                    # Core Dart package (cross-platform)
├── rift_flutter/            # Flutter integration
├── rift_generator/          # Code generator
├── rift_inspector/          # DevTools inspector
├── benchmarks/              # Performance benchmarks
├── overrides/               # Compatibility overrides
└── website/                 # Documentation website
```

## 📦 Package Details

### 1. rift (Core Package)

**Location:** `rift/`

**Description:** The core Dart package providing the database functionality.

**Dependencies:**
- Dart SDK: ^3.8.0
- meta: ^1.14.0
- crypto: ^3.0.0
- web: ">=0.5.0 <2.0.0"
- isolate_channel: ^0.6.0
- json_annotation: ^4.9.0

**Supported Platforms:**
- ✅ Android
- ✅ iOS
- ✅ Web (Chrome, Firefox, Safari, Edge)
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ✅ All Dart platforms (VM, AOT, JIT)

**Key Components:**

#### Core Systems
- **backend/**: Storage backends (VM, JS, Stub)
  - `vm/`: Native Dart VM backend
  - `js/`: JavaScript/Web backend (IndexedDB)
  - `stub/`: Stub implementation for testing

- **binary/**: Binary serialization
  - Binary reader/writer
  - Frame-based storage format
  - Type system

- **box/**: Box management
  - Box operations (get, put, delete, etc.)
  - Box collections
  - Transaction support

- **adapters/**: Type adapters
  - Built-in adapters for common types
  - Custom adapter support

#### Advanced Features
- **query/**: Query engine
  - Query builder
  - Live queries
  - Query optimization

- **index/**: Indexing system
  - Secondary indexes
  - Composite indexes
  - Index management

- **transaction/**: Transaction support
  - ACID transactions
  - Cross-box transactions
  - Transaction isolation

- **encryption/**: Security
  - AES-256 encryption
  - Field-level encryption
  - Access control

- **compression/**: Data compression
  - LZ4 compression
  - Dictionary compression

- **cache/**: Caching strategies
  - LRU cache
  - Read cache
  - Adaptive caching

- **sync/**: Synchronization
  - Change Data Capture (CDC)
  - Replication
  - CRDT support

- **migration/**: Schema migration
  - Schema versioning
  - Migration tools
  - Hive migration helper

### 2. rift_flutter (Flutter Integration)

**Location:** `rift_flutter/`

**Description:** Flutter-specific integration providing automatic initialization and Flutter adapters.

**Dependencies:**
- Dart SDK: ^3.4.0
- Flutter: >=3.27.0
- rift: ^1.0.0
- path_provider: ^2.0.10
- path: ^1.8.2

**Supported Platforms:**
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

**Key Components:**
- **adapters/**: Flutter-specific adapters
  - Color adapter
  - TimeOfDay adapter
- **integration/**: Flutter integration
  - Automatic initialization
  - Path management

### 3. rift_generator (Code Generator)

**Location:** `rift_generator/`

**Description:** Code generator for automatic TypeAdapter generation.

**Dependencies:**
- Dart SDK: ^3.4.0
- build: ^4.0.0
- source_gen: ^4.0.0
- rift: ^1.0.0
- analyzer: ^12.0.0

**Supported Platforms:**
- ✅ All Dart platforms (build-time tool)

**Key Components:**
- **adapter_builder/**: Adapter builders
  - Class adapter builder
  - Enum adapter builder
- **generator/**: Code generation
  - TypeAdapter generator
  - Schema generation
- **helper/**: Helper utilities
  - Type helpers
  - Annotation helpers

### 4. rift_inspector (DevTools Inspector)

**Location:** `rift_inspector/`

**Description:** DevTools extension for visual database inspection.

**Dependencies:**
- Dart SDK: ^3.9.0
- Flutter SDK
- rift: ^1.0.0
- devtools_extensions: ^0.5.0
- vm_service: ^15.0.0

**Supported Platforms:**
- ✅ Desktop (Windows, macOS, Linux)
- ✅ Web (DevTools)

**Key Components:**
- **inspector/**: Database inspection UI
- **connect/**: DevTools connection
- **visualizer/**: Data visualization

## 🌍 Platform Support Matrix

| Platform | rift | rift_flutter | rift_generator | rift_inspector |
|----------|------|--------------|----------------|----------------|
| Android  | ✅   | ✅           | ✅ (build)     | ❌             |
| iOS      | ✅   | ✅           | ✅ (build)     | ❌             |
| Web      | ✅   | ✅           | ✅ (build)     | ✅             |
| Windows  | ✅   | ✅           | ✅ (build)     | ✅             |
| macOS    | ✅   | ✅           | ✅ (build)     | ✅             |
| Linux    | ✅   | ✅           | ✅ (build)     | ✅             |

## 🔧 Backend Architecture

### VM Backend (Native)
- **File:** `src/backend/vm/`
- **Storage:** File-based storage
- **Performance:** Maximum performance
- **Use Case:** Desktop, mobile apps

### JS Backend (Web)
- **File:** `src/backend/js/`
- **Storage:** IndexedDB
- **Performance:** Good performance
- **Use Case:** Web applications

### Stub Backend (Testing)
- **File:** `src/backend/stub/`
- **Storage:** In-memory
- **Performance:** N/A (testing only)
- **Use Case:** Unit tests

## 🎯 Key Features

### Core Features (75+)
- **Query Engine**: Query Builder, Live Queries, Secondary & Composite Indexes, Cursor Iterator, Query Optimization
- **Data & Schema**: ACID Transactions, Cross-Box Transactions, Schema Migration, Relations, Bulk Operations, Typed Boxes, Schema Validation, Middleware, Partitioning, Aggregation Pipeline, Data Diff & Patch, Data Versioning, Transform Pipeline, Rate Limiting
- **Security**: AES-256 Encryption with PBKDF2+HMAC, Field-Level Encryption, Access Control, Data Masking, Data Sanitization, Audit Log
- **Performance**: LZ4 Compression, LRU Cache, Read Cache, Adaptive Caching, In-Memory Mode, WAL Recovery, Background Compaction, Binary Storage, Dictionary Compression, Pluggable Storage, TTL/Auto-Expiry, Time Travel/Undo, Time-Series Data, Snapshot Isolation, Bloom Filters
- **Sync & Distribution**: Sync Layer, Change Data Capture, Replication, CRDT, Event Sourcing, Connection Pooling, Observable Store
- **Developer Tools**: Testing Utilities, Code Generator, No-Codegen Mode, DevTools Inspector, Performance Profiler, Metrics/Observability, Dart 3 Records, Extension Types, Plugin Architecture, CLI Tools

## 📊 Performance Characteristics

### Storage Format
- **Binary Format**: Custom frame-based binary format
- **Compression**: LZ4 compression support
- **Size**: Optimized for minimal storage footprint

### Query Performance
- **Indexing**: Secondary and composite indexes
- **Optimization**: Query optimization engine
- **Caching**: Multi-level caching strategy

### Concurrency
- **Isolates**: Multi-isolate support
- **Transactions**: ACID-compliant transactions
- **Locking**: Optimistic locking

## 🔐 Security Features

### Encryption
- **Algorithm**: AES-256
- **Key Derivation**: PBKDF2+HMAC
- **Scope**: Database-level and field-level encryption

### Access Control
- **Role-based access control**
- **Field-level permissions**
- **Data masking**

### Audit
- **Audit logging**
- **Change tracking**
- **Data sanitization**

## 🚀 Deployment

### Publishing Order
1. `rift` (core package)
2. `rift_flutter` (depends on rift)
3. `rift_generator` (depends on rift)
4. `rift_inspector` (depends on rift, rift_flutter)

### Version Compatibility
- All packages use semantic versioning
- Major version 1.0.0
- Compatible with Dart SDK ^3.8.0
- Compatible with Flutter SDK >=3.27.0

## 📝 Development Workflow

### Building
```bash
cd rift
dart pub get
dart build
```

### Testing
```bash
cd rift
dart test
```

### Code Generation
```bash
dart run build_runner build
```

## 🎨 Architecture Patterns

### Design Patterns Used
- **Repository Pattern**: Box management
- **Factory Pattern**: Adapter creation
- **Builder Pattern**: Query builder
- **Observer Pattern**: Live queries
- **Strategy Pattern**: Backend selection
- **Adapter Pattern**: Type adapters

### SOLID Principles
- **Single Responsibility**: Each component has one responsibility
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Backend interfaces are interchangeable
- **Interface Segregation**: Minimal interfaces
- **Dependency Inversion**: Depend on abstractions

## 🔍 Code Organization

### Layered Architecture
```
┌─────────────────────────────────┐
│   Application Layer (Flutter)   │
├─────────────────────────────────┤
│   Integration Layer (rift_flutter)│
├─────────────────────────────────┤
│   Core Layer (rift)              │
│   ├── Query Engine              │
│   ├── Storage Backend           │
│   ├── Type System               │
│   └── Security                  │
├─────────────────────────────────┤
│   Platform Layer (VM/JS)        │
└─────────────────────────────────┘
```

## 📚 Module Dependencies

```
rift_flutter
    ↓
rift
    ↓
Dart SDK / Flutter SDK

rift_generator
    ↓
rift
    ↓
build_runner / analyzer

rift_inspector
    ↓
rift + rift_flutter
    ↓
devtools_extensions
```

## 🎯 Use Cases

### Mobile Apps
- Offline-first applications
- Local data caching
- User preferences
- Shopping carts

### Web Apps
- Progressive Web Apps (PWA)
- Browser-based applications
- Client-side storage
- Session management

### Desktop Apps
- Desktop applications
- Local databases
- Data persistence
- Settings management

### Server Apps
- Server-side Dart applications
- Data caching
- Session storage
- Temporary data

## 🔮 Future Roadmap

### Planned Features
- GraphQL integration
- GraphQL subscriptions
- Cloud sync providers
- More compression algorithms
- Advanced query optimization
- Machine learning integration
- Real-time collaboration

## 📖 Documentation

### Available Documentation
- README.md (project overview)
- CHANGELOG.md (version history)
- ARCHITECTURE.md (this file)
- API documentation (dart doc)
- Example applications

### Learning Resources
- Example apps in `rift/example/`
- Integration tests in `rift/test/`
- Benchmarks in `benchmarks/`

## 🤝 Contributing

### Code Style
- Dart effective style guide
- 100 character line length
- Type annotations for public APIs
- Documentation comments for public APIs

### Testing
- Unit tests for core functionality
- Integration tests for backend-specific features
- Performance benchmarks
- Cross-platform testing

## 📞 Support

### GitHub
- Repository: https://github.com/idris-ghamid/rift
- Issues: https://github.com/idris-ghamid/rift/issues
- Discussions: https://github.com/idris-ghamid/rift/discussions

### Social
- LinkedIn: https://www.linkedin.com/in/idris-ghamid
- Instagram: https://www.instagram.com/idris.ghamid
- X (Twitter): https://x.com/IdrisGhamid

---

**Version:** 1.0.0  
**Last Updated:** May 30, 2026  
**Author:** Idris Ghamid
