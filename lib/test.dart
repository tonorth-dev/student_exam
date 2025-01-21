import 'package:flutter/material.dart';

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          height: 810, // Fixed height to constrain the layout
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar
              Row(
                children: [
                  _buildSidebar(),
                  const SizedBox(width: 310), // Space for sidebar width
                ],
              ),

              // Main Content
              Padding(
                padding: const EdgeInsets.only(left: 40), // Assuming 350 - Sidebar width
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40), // Equivalent to top: 40
                    _buildHeader(),
                    const SizedBox(height: 9.73),
                    _buildListItems(),
                  ],
                ),
              ),

              // Space for bottom positioning
              const Spacer(),

              // Bottom Navigation
              Padding(
                padding: const EdgeInsets.only(left: 874.99 - 310), // Adjust based on sidebar width
                child: _buildBottomNavigation(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 310,
      height: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(left: 39.90, top: 38.18),
        child: _buildSidebarContent(),
      ),
    );
  }

  Widget _buildSidebarContent() {
    // Placeholder for sidebar content
    return Container(
      width: 231.67,
      height: 53.29,
      // Add your sidebar elements here
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 46,
      color: Colors.transparent,
      child: const Text(
        '2024高频考题（42章经）',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontFamily: 'PingFang SC',
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildListItems() {
    return SizedBox(
      width: double.infinity,
      height: 276, // Adjust this height based on your content or logic
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 6, // Example count, adjust as needed
        itemBuilder: (context, index) => Container(
          width: double.infinity,
          height: 46,
          color: Colors.white.withOpacity(0.8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: ShapeDecoration(
                  color: index == 2 ? Colors.red : Colors.black,
                  shape: const OvalBorder(),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '2024高频考题（42章经）(1)_0$index',
                style: TextStyle(
                  color: index == 2 ? Colors.red : Colors.black,
                  fontSize: 16,
                  fontFamily: 'PingFang SC',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildButton('上一页', const Color(0xFFFF4F1A)),
        const SizedBox(width: 25),
        _buildButton('下一页', const Color(0xFFFF4F1A)),
        const SizedBox(width: 25),
        _buildButton('退出', const Color(0xFFFF4F1A)),
      ],
    );
  }

  Widget _buildButton(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.00, 1.00),
          end: Alignment(0, -1),
          colors: [Color(0xFFFFD566), Colors.white],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF92D37), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontFamily: 'PingFang SC',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}