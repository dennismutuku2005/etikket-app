import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Core
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';

// Data
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/ticket_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/ticket_repository_impl.dart';

// Domain
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/ticket_repository.dart';
import 'domain/usecases/get_saved_session_usecase.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'domain/usecases/lookup_ticket_usecase.dart';
import 'domain/usecases/verify_ticket_usecase.dart';

// Presentation
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/scanner_controller.dart';
import 'presentation/controllers/settings_controller.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Core Services
  final apiClient = ApiClient();

  // Initialize Data Sources
  final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
  final authLocalDataSource = AuthLocalDataSourceImpl();
  final ticketRemoteDataSource = TicketRemoteDataSourceImpl(apiClient: apiClient);

  // Initialize Repositories
  final AuthRepository authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    localDataSource: authLocalDataSource,
  );
  final TicketRepository ticketRepository = TicketRepositoryImpl(
    remoteDataSource: ticketRemoteDataSource,
  );

  // Initialize Use Cases
  final loginUseCase = LoginUseCase(authRepository);
  final getSavedSessionUseCase = GetSavedSessionUseCase(authRepository);
  final logoutUseCase = LogoutUseCase(authRepository);
  final lookupTicketUseCase = LookupTicketUseCase(ticketRepository);
  final verifyTicketUseCase = VerifyTicketUseCase(ticketRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController(apiClient: apiClient),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(
            loginUseCase: loginUseCase,
            getSavedSessionUseCase: getSavedSessionUseCase,
            logoutUseCase: logoutUseCase,
          ),
        ),
        ChangeNotifierProvider<ScannerController>(
          create: (_) => ScannerController(
            lookupTicketUseCase: lookupTicketUseCase,
            verifyTicketUseCase: verifyTicketUseCase,
          ),
        ),
      ],
      child: const EtikketGateApp(),
    ),
  );
}

class EtikketGateApp extends StatelessWidget {
  const EtikketGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eTikket Gate Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
