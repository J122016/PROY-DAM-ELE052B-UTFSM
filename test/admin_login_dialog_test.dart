import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_dam/presentation/components/admin_login_dialog.dart';

void main() {
  testWidgets('submits the email and password and closes on success', (
    tester,
  ) async {
    String? submittedEmail;
    String? submittedPassword;
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AdminLoginDialog(
                    onSignIn: (email, password) async {
                      submittedEmail = email;
                      submittedPassword = password;
                    },
                  ),
                );
              },
              child: const Text('Open login'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open login'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(submittedEmail, 'admin@example.com');
    expect(submittedPassword, '123456');
    expect(result, isTrue);
    expect(find.byType(AdminLoginDialog), findsNothing);
  });

  testWidgets('shows an error when Firebase rejects the credentials', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AdminLoginDialog(
                  onSignIn: (email, password) async {
                    throw FirebaseAuthException(code: 'invalid-credential');
                  },
                ),
              ),
              child: const Text('Open login'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open login'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrect');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.byType(AdminLoginDialog), findsOneWidget);
  });
}
