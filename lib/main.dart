import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'api_service.dart';

void main() {
  runApp(const PhishingAgentApp());
}

class PhishingAgentApp extends StatelessWidget {
  const PhishingAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phishing Detector Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD400),
          primary: const Color(0xFF1E1E1E),
          secondary: const Color(0xFFFFD400),
          surface: const Color(0xFFF7F4EF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F4EF),
      ),
      home: const AnalysisScreen(),
    );
  }
}

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String? _analysisResult;

  late AnimationController _radarController;
  late AnimationController _blinkingController;

  int _currentStep = 1;
  int _progressPercentage = 12;
  Timer? _stepTimer;
  Future<String>? _apiAnalysisFuture;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _blinkingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _textController.dispose();
    _radarController.dispose();
    _blinkingController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _textController.text = data.text!;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El portapapeles está vacío o no contiene texto.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _cancelAnalysis() {
    _stepTimer?.cancel();
    _radarController.stop();
    setState(() {
      _isLoading = false;
      _analysisResult = null;
    });
  }

  Future<void> _analyzeMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa un enlace o texto para analizar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _analysisResult = null;
      _currentStep = 1;
      _progressPercentage = 12;
    });

    _radarController.repeat();
    // llamada a la API en paralelo
    _apiAnalysisFuture = ApiService.analyzeText(message);
    // progreso por pasos sincronizado
    _stepTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_currentStep == 1) {
          if (_progressPercentage < 42) {
            _progressPercentage += 3;
          } else {
            _currentStep = 2;
          }
        } else if (_currentStep == 2) {
          if (_progressPercentage < 78) {
            _progressPercentage += 3;
          } else {
            _currentStep = 3;
          }
        } else if (_currentStep == 3) {
          if (_progressPercentage < 93) {
            _progressPercentage += 1;
          }
        }
      });

      if (_progressPercentage >= 85) {
        timer.cancel();

        try {
          final result = await _apiAnalysisFuture!;
          if (!mounted) return;

          setState(() {
            _progressPercentage = 100;
          });

          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;

          setState(() {
            _isLoading = false;
            _analysisResult = result;
          });
          _radarController.stop();
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _analysisResult = '⚠️ Error de conexión: No se pudo contactar al agente de seguridad.';
          });
          _radarController.stop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading ? _buildLoadingScreen() : _buildMainScreen(),
      ),
    );
  }

  //  Pantalla de inicio
  Widget _buildMainScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD400),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.shield,
                  color: Colors.black,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Phishing Detector Agent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gpp_good,
                  size: 14,
                  color: Colors.black,
                ),
                SizedBox(width: 4),
                Text(
                  'VERIFICACIÓN SEGURA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // TÍTULOS PRINCIPALES
          const Text(
            '¿Dudas de un mensaje o enlace?',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pégalo aquí y te diremos al instante si es confiable.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // CONTENEDOR PRINCIPAL / CARD GRISÁCEO
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEFECE6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 18,
                          color: Colors.black54,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'CONTENIDO A COMPROBAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _pasteFromClipboard,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 14,
                              color: Colors.black87,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'PEGAR PORTAPAPELES',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: 6,
                    minLines: 4,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Pega aquí el enlace o texto del SMS...',
                      hintStyle: TextStyle(
                        color: Colors.black38,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _analyzeMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ANALIZAR AHORA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONSEJO RÁPIDO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE53935),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ningún banco o entidad legítima te pedirá tu contraseña, PIN, código secreto o información sensible a través de un SMS.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // REPORTE DE RESULTADO (SI EXISTE)
          if (_analysisResult != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resultado del Análisis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    setState(() {
                      _analysisResult = null;
                    });
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEFECE6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SelectableText(
                _analysisResult!,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // pantalla de carga
  Widget _buildLoadingScreen() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black12,
                width: 1,
              ),
            ),
          ),
          child: const Text(
            'RESULTADO',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(180, 180),
                        painter: _RadarCirclesPainter(),
                      ),
                      // Línea de barrido de radar giratoria
                      RotationTransition(
                        turns: _radarController,
                        child: CustomPaint(
                          size: const Size(180, 180),
                          painter: _RadarSweepPainter(),
                        ),
                      ),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD400),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Colors.black,
                          size: 42,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFECE6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _blinkingController,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ESCANEO EN TIEMPO REAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'ANALIZANDO ENLACE...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1E1E),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Comprobando la autenticidad del remitente y el sitio web para protegerte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PROGRESO DE SEGURIDAD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '$_progressPercentage%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 10,
                          child: LinearProgressIndicator(
                            value: _progressPercentage / 100,
                            backgroundColor: const Color(0xFFEFECE6),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD400)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildStepTile(
                        stepNumber: '1',
                        title: 'Envio del Paquete',
                        subtitle: 'Paquete enviado',
                        icon: Icons.check,
                        status: _currentStep > 1 ? StepStatus.completed : StepStatus.analyzing,
                      ),
                      const SizedBox(height: 12),

                      _buildStepTile(
                        stepNumber: '2',
                        title: 'Analizando Patrones',
                        subtitle: 'Comparando',
                        icon: Icons.sync,
                        status: _currentStep == 2
                            ? StepStatus.analyzing
                            : (_currentStep > 2 ? StepStatus.completed : StepStatus.pending),
                      ),
                      const SizedBox(height: 12),

                      _buildStepTile(
                        stepNumber: '3',
                        title: 'Verificando',
                        subtitle: 'A la espera de una respuesta',
                        icon: Icons.lock_outline,
                        status: _currentStep == 3 ? StepStatus.analyzing : StepStatus.pending,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cancelAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5DFD5),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text(
                      'CANCELAR ANÁLISIS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTile({
    required String stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required StepStatus status,
  }) {
    Color cardBgColor = const Color(0xFFF7F4EF);
    Color iconBgColor = Colors.black12;
    Color iconColor = Colors.black54;
    String badgeText = 'PENDIENTE';
    Color badgeTextBgColor = const Color(0xFFEFECE6);
    Color badgeTextColor = Colors.black54;

    switch (status) {
      case StepStatus.completed:
        cardBgColor = const Color(0xFFF5F2EB);
        iconBgColor = const Color(0xFF1E1E1E);
        iconColor = Colors.white;
        badgeText = 'LISTO';
        badgeTextBgColor = const Color(0xFFEFECE6);
        badgeTextColor = Colors.black87;
        break;
      case StepStatus.analyzing:
        cardBgColor = const Color(0xFFE3ECFC);
        iconBgColor = const Color(0xFF2979FF);
        iconColor = Colors.white;
        badgeText = 'ANALIZANDO';
        badgeTextBgColor = Colors.white;
        badgeTextColor = const Color(0xFF2979FF);
        break;
      case StepStatus.pending:
        cardBgColor = const Color(0xFFF5F2EB);
        iconBgColor = const Color(0xFF1E1E1E).withValues(alpha: 0.12);
        iconColor = Colors.black26;
        badgeText = 'PENDIENTE';
        badgeTextBgColor = const Color(0xFFEFECE6);
        badgeTextColor = Colors.black38;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$stepNumber. $title',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: status == StepStatus.pending ? Colors.black38 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: status == StepStatus.pending ? Colors.black26 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeTextBgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum StepStatus { completed, analyzing, pending }

class _RadarCirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (double radius = 45; radius <= 90; radius += 22.5) {
      _drawDashedCircle(canvas, center, radius, paint);
    }
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const int dashCount = 45;
    final double circumference = 2 * math.pi * radius;
    final double dashWidth = circumference / (dashCount * 2);

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * 2 * math.pi) / dashCount;
      final double sweepAngle = dashWidth / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarSweepPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          Colors.black.withValues(alpha: 0.15),
          Colors.black.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25],
        transform: const GradientRotation(0.0),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(center, radius, sweepPaint);

    final linePaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 2.0;

    canvas.drawLine(
      center,
      Offset(center.dx + radius * math.cos(0), center.dy + radius * math.sin(0)),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
