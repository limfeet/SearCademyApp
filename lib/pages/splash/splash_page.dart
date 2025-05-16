import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:searcademy/config/splash/splash_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Future<void> initAsync() async {
    final begin = DateTime.now();
    final end = DateTime.now();
    final elapsed = end.difference(begin);
    if (elapsed.inSeconds < 2) {
      final delay = Duration(milliseconds: 2000 - elapsed.inMilliseconds);
      await Future.delayed(delay);
    }

    // 이제 강제로 본화면으로 점프 뛰게하자.
  }

  @override
  void initState() {
    //SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    super.initState();
    initAsync();
  }

  @override
  Widget build(BuildContext context) {
    final splashState = ref.read(splashCompleteProvider.notifier);

    Future.delayed(Duration(seconds: 5), () {
      splashState.state = true; // Splash 완료
    });

    final title = Slide(
        child: Padding(
      padding: const EdgeInsets.all(50.0),
      //child: Image.asset('images/landing-logo_new.webp',
      child: Image.asset('images/searcademy_splash_logo.webp',
          fit: BoxFit.fitWidth, alignment: Alignment.center),
    ));

    const version = Slide(
        delay: Duration(milliseconds: 100),
        child: Text("SEARCH ACADEMY APP",
            style: TextStyle(
                color: Color.fromARGB(137, 206, 241, 197), fontSize: 20.0)));

    final text = Align(
        alignment: const Alignment(0.0, -0.2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            title,
            const SizedBox(
              height: 10.0,
            ),
            version,
          ],
        ));

    //final back = Image.asset("images/landing_new.webp",
    final back = Image.asset("images/landing_new_1.webp",
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center);

    return Scaffold(
        key: const Key('splashPage'),
        body: Stack(
          children: <Widget>[
            back,
            text,
          ],
        ));
  }
}

class Slide extends StatefulWidget {
  final Widget child;
  final Duration? delay;

  const Slide({super.key, required this.child, this.delay});

  @override
  _SlideState createState() => _SlideState();
}

class _SlideState extends State<Slide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  static final Animatable<Offset> _tween = Tween<Offset>(
    begin: const Offset(-2.0, 0.0),
    end: Offset.zero,
  ).chain(CurveTween(
    curve: Curves.fastOutSlowIn,
  ));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = _controller.drive(_tween);
    if (widget.delay == null) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay!).then((_) => _controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _animation, child: widget.child);
  }
}
