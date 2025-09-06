import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'constants/theme.dart';
import 'constants/theme_provider.dart';
import 'services/spaced_repetition_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Thực hiện daily check cho Spaced Repetition khi app khởi động
  final spacedRepetitionService = SpacedRepetitionService();
  await spacedRepetitionService.performDailyCheck();
  
  runApp(const EnglishVocabApp());
}

class EnglishVocabApp extends StatelessWidget {
  const EnglishVocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'English Vocabulary App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
