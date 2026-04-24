// Core - App-wide utilities, constants, and theme
export 'core/constants/app_constants.dart';
export 'core/theme/app_theme.dart';

// Domain - Business entities and repository interfaces
export 'domain/entities/obd_reading.dart';
export 'domain/entities/vehicle_info.dart';
export 'domain/repositories/obd_repository.dart';

// Data - Repository implementations and data models
export 'data/models/obd_device_model.dart';
export 'data/repositories/obd_repository_impl.dart';

// Presentation - Providers and UI
export 'presentation/providers/obd_provider.dart';

// Services - Original service layer (kept for compatibility)
export 'services/obd_manager.dart';
export 'services/obd_service.dart';

// Screens
export 'screens/splash_screen.dart';
export 'screens/dashboard_screen.dart';
export 'screens/dtc_screen.dart';

// Widgets
export 'widgets/common_widgets.dart';