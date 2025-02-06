import 'dart:async';

class Countdown {
  // Private constructor to prevent direct instantiation
  Countdown._internal({required this.totalDuration})
      : currentSeconds = totalDuration,
        lastSegmentTime = totalDuration {
    _isRunningController.add(isRunning);
    _segmentsController.add([]);
  }

  // Static field to hold the single instance of Countdown
  static final Countdown _instance = Countdown._internal(totalDuration: 0);

  // Factory constructor to return the instance
  factory Countdown({required int totalDuration}) {
    _instance.totalDuration = totalDuration;
    _instance.reset(); // Reset to new total duration
    return _instance;
  }

  final StreamController<int> _tickController = StreamController<int>.broadcast();
  final StreamController<bool> _isRunningController = StreamController<bool>.broadcast();
  final StreamController<List<String>> _segmentsController = StreamController<List<String>>.broadcast();

  Timer? timer;
  int totalDuration; // Total duration in seconds
  bool isRunning = false;
  bool isStopped = false; // Flag to prevent further starts
  bool showElapsedTime = false;
  int currentSeconds; // Track remaining time manually
  int lastSegmentTime; // Track time of the last segment
  List<int> segments = []; // Store segments in seconds

  Stream<int> get tickStream => _tickController.stream;
  Stream<bool> get isRunningStream => _isRunningController.stream;
  Stream<List<String>> get segmentsStream => _segmentsController.stream;

  void startOrResume() {
    if (isStopped) return; // Prevent starting if stopped
    if (isRunning) {
      pause();
    } else {
      startTimer();
    }
  }

  void startTimer() {
    if (isRunning) return;
    
    isRunning = true;
    showElapsedTime = false;
    _isRunningController.add(isRunning);
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (currentSeconds > 0) {
        currentSeconds--;
        _tickController.add(currentSeconds);
      } else {
        timer.cancel();
        isRunning = false;
        _isRunningController.add(isRunning);
      }
    });
  }

  void pause() {
    if (!isRunning) return;
    isRunning = false;
    showElapsedTime = false;
    _isRunningController.add(isRunning);
    timer?.cancel();
  }

  void restart(int totalDuration) {
    if (isStopped) return; // Prevent restart if stopped
    segments.clear(); // Clear segments when restarting
    this.totalDuration = totalDuration;
    currentSeconds = totalDuration;
    lastSegmentTime = totalDuration;
    isRunning = false;
    _isRunningController.add(isRunning);
    _tickController.add(currentSeconds);
    _segmentsController.add([]); // Ensure the segments stream is updated on restart
  }

  void reset() {
    if (isStopped) {
      isStopped = false;
    }
    timer?.cancel();
    isRunning = false;
    showElapsedTime = false;
    currentSeconds = totalDuration;
    lastSegmentTime = totalDuration;
    segments.clear();
    _isRunningController.add(isRunning);
    _tickController.add(currentSeconds);
    _segmentsController.add([]);
  }

  void stop() {
    timer?.cancel();
    isRunning = false;
    isStopped = true; // Mark as stopped
    showElapsedTime = true;
    _isRunningController.add(isRunning);
  }

  void markSegment() {
    if (isRunning) {
      final segmentDuration = lastSegmentTime - currentSeconds;
      lastSegmentTime = currentSeconds;
      segments.add(segmentDuration);
      _segmentsController.add(
        segments.map((s) => "${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}").toList(),
      );
    }
  }

  void dispose() {
    timer?.cancel();
    _tickController.close();
    _isRunningController.close();
    _segmentsController.close();
  }
}