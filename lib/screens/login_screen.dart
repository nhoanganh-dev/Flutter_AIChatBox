import 'package:chat_box/services/auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _logoController;
  late AnimationController _buttonController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _particleAnimation;

  bool _isButtonPressed = false;
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 30; i++) {
      particles.add(Particle());
    }

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.bounceOut),
    );

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(_glowController);

    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_particleController);

    Future.delayed(const Duration(milliseconds: 500), () {
      _logoController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    _buttonController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onGoogleLoginPressed() async {
    setState(() => _isButtonPressed = true);

    for (int i = 0; i < 20; i++) {
      particles.add(Particle.explosion(buttonCenter));
    }
    final AuthService authService = AuthService();

    await authService.googleSignIn();
  }

  Offset buttonCenter = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundPainter(
                  animation: _backgroundController.value,
                ),
                child: Container(),
              );
            },
          ),
          AnimatedBuilder(
            animation: _particleAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: particles,
                  animation: _particleAnimation.value,
                ),
                child: Container(),
              );
            },
          ),
          // Main content
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo with rotation
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _rotateAnimation,
                      _scaleAnimation,
                    ]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        return Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(
                                  _glowAnimation.value,
                                ),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: Colors.purpleAccent.withOpacity(
                                  _glowAnimation.value * 0.5,
                                ),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const ChatGPTLogo(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Title with typing animation
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      final text = 'Welcome to ChatGPT';
                      final visibleChars =
                          (_logoController.value * text.length).round();
                      return Text(
                        text.substring(0, visibleChars),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.blue.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                  // Google login button with bounce animation
                  AnimatedBuilder(
                    animation: _buttonController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _bounceAnimation.value,
                        child: _buildGoogleLoginButton(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleLoginButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        buttonCenter = Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2 + 100,
        );

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isButtonPressed ? 280 : 300,
            height: _isButtonPressed ? 50 : 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isButtonPressed ? 0.2 : 0.3),
                  blurRadius: _isButtonPressed ? 10 : 20,
                  offset: Offset(0, _isButtonPressed ? 5 : 10),
                ),
                BoxShadow(
                  color: Colors.blue.withOpacity(_isButtonPressed ? 0.3 : 0.5),
                  blurRadius: _isButtonPressed ? 15 : 30,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _onGoogleLoginPressed,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google logo
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isButtonPressed ? 24 : 30,
                      height: _isButtonPressed ? 24 : 30,
                      child: Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.login, color: Colors.blue);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: _isButtonPressed ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double life;

  Particle()
    : position = Offset(
        math.Random().nextDouble() * 400,
        math.Random().nextDouble() * 800,
      ),
      velocity = Offset(
        (math.Random().nextDouble() - 0.5) * 2,
        (math.Random().nextDouble() - 0.5) * 2,
      ),
      color = Colors.primaries[math.Random().nextInt(Colors.primaries.length)]
          .withOpacity(0.5),
      size = math.Random().nextDouble() * 4 + 2,
      life = 1.0;

  Particle.explosion(Offset center)
    : position = center,
      velocity = Offset(
        (math.Random().nextDouble() - 0.5) * 20,
        (math.Random().nextDouble() - 0.5) * 20,
      ),
      color = Colors.primaries[math.Random().nextInt(Colors.primaries.length)],
      size = math.Random().nextDouble() * 6 + 4,
      life = 1.0;

  void update(double animation) {
    position += velocity;
    life -= 0.01;
    size *= 0.99;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;

  ParticlePainter({required this.particles, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(animation);

      if (particle.life <= 0) {
        continue;
      }

      final paint =
          Paint()
            ..color = particle.color.withOpacity(particle.life)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.size, paint);
    }

    // Remove dead particles
    particles.removeWhere((particle) => particle.life <= 0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ChatGPTLogo extends StatelessWidget {
  const ChatGPTLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Hexagon background
        // Your logo
        ClipPath(
          child: Image.asset(
            'assets/images/chat-logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class HexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.2;

    // Draw hexagon background
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BackgroundPainter extends CustomPainter {
  final double animation;

  BackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A237E),
              const Color(0xFF0D47A1),
              Colors.black,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Animated gradient orbs
    for (int i = 0; i < 5; i++) {
      final orbAnimation = (animation + i * 0.2) % 1.0;
      final orbRadius = 100.0 + 150.0 * math.sin(orbAnimation * math.pi);
      final orbOpacity = 0.2 + 0.3 * math.sin(orbAnimation * math.pi);

      final orbPaint =
          Paint()
            ..shader = RadialGradient(
              colors: [
                Colors.blue.withOpacity(orbOpacity),
                Colors.purple.withOpacity(orbOpacity * 0.5),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(
              Rect.fromCircle(
                center: Offset(
                  size.width * (0.2 + i * 0.2) +
                      50 * math.sin(orbAnimation * 2 * math.pi),
                  size.height * (0.3 + i * 0.1) +
                      50 * math.cos(orbAnimation * 2 * math.pi),
                ),
                radius: orbRadius,
              ),
            );

      canvas.drawCircle(
        Offset(
          size.width * (0.2 + i * 0.2) +
              50 * math.sin(orbAnimation * 2 * math.pi),
          size.height * (0.3 + i * 0.1) +
              50 * math.cos(orbAnimation * 2 * math.pi),
        ),
        orbRadius,
        orbPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
