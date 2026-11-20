import 'package:flutter/material.dart';
import '../doctors/doctor_list_screen.dart';

class SynthoXAIScreen extends StatefulWidget {
  const SynthoXAIScreen({super.key});

  @override
  State<SynthoXAIScreen> createState() => _SynthoXAIScreenState();
}

class _SynthoXAIScreenState extends State<SynthoXAIScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAnalyzing = false;

  final List<Map<String, dynamic>> _chatHistory = [
    {
      'sender': 'ai',
      'content': 'Hello Sarah 👋 I am SynthoX AI, your clinical triage assistant. Describe any symptoms you are experiencing today.',
      'type': 'text',
    },
  ];

  final List<String> _quickPrompts = [
    'Dry cough and mild fever since yesterday',
    'Frequent headache and eye strain',
    'Stomach pain after meals',
    'Sharp chest tightness when climbing stairs',
  ];

  void _sendSymptom(String symptomText) async {
    if (symptomText.trim().isEmpty) return;

    setState(() {
      _chatHistory.add({
        'sender': 'user',
        'content': symptomText.trim(),
        'type': 'text',
      });
      _isAnalyzing = true;
    });

    _inputController.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final analysis = _generateTriageAnalysis(symptomText);
      setState(() {
        _isAnalyzing = false;
        _chatHistory.add({
          'sender': 'ai',
          'type': 'triage',
          'riskLevel': analysis['riskLevel'],
          'riskColor': analysis['riskColor'],
          'summary': analysis['summary'],
          'recommendation': analysis['recommendation'],
          'specialist': analysis['specialist'],
          'redFlags': analysis['redFlags'],
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Map<String, dynamic> _generateTriageAnalysis(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('chest') || lower.contains('breath') || lower.contains('heart')) {
      return {
        'riskLevel': 'URGENT CARE RECOMMENDED',
        'riskColor': Colors.red,
        'summary': 'Symptoms involving chest tightness or breathlessness require prompt medical evaluation to rule out acute cardiac or pulmonary issues.',
        'recommendation': 'Consult a Cardiologist or visit urgent care immediately if pain radiates to jaw/arm.',
        'specialist': 'Cardiologist',
        'redFlags': 'Shortness of breath, sweating, pressure radiating to neck or left arm.',
      };
    } else if (lower.contains('cough') || lower.contains('fever') || lower.contains('cold')) {
      return {
        'riskLevel': 'MODERATE RISK',
        'riskColor': Colors.orange.shade800,
        'summary': 'Cough accompanied by fever is common in upper respiratory tract viral infections or bronchitis.',
        'recommendation': 'Rest, maintain hydration, and schedule a consultation with a General Practitioner.',
        'specialist': 'General Practitioner',
        'redFlags': 'High fever above 102°F lasting more than 3 days, difficulty breathing.',
      };
    } else {
      return {
        'riskLevel': 'LOW RISK / GENERAL INQUIRY',
        'riskColor': Colors.blue.shade800,
        'summary': 'Symptoms appear mild. Regular monitoring and hydration are advised.',
        'recommendation': 'Book a routine checkup with a General Physician if symptoms persist beyond 48 hours.',
        'specialist': 'General Physician',
        'redFlags': 'Sudden worsening of symptoms or onset of severe pain.',
      };
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00B8D4).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, color: Color(0xFF00B8D4), size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SynthoX AI Triage',
                  style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Clinical Guidance & Specialty Referral',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Medical Disclaimer Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFFFF8E1),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Triage provides guidance only. Call emergency services immediately for life-threatening conditions.',
                    style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length + (_isAnalyzing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chatHistory.length && _isAnalyzing) {
                  return _buildAnalyzingBubble();
                }

                final item = _chatHistory[index];
                if (item['type'] == 'triage') {
                  return _buildTriageCard(item);
                }

                return _buildTextMessageBubble(
                  item['content'],
                  isMe: item['sender'] == 'user',
                );
              },
            ),
          ),

          // Quick Prompts Row
          if (!_isAnalyzing)
            Container(
              height: 44,
              padding: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickPrompts.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _sendSymptom(_quickPrompts[index]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00B8D4).withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Text(
                          _quickPrompts[index],
                          style: const TextStyle(fontSize: 12, color: Color(0xFF0D47A1), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _inputController,
                        onSubmitted: (val) => _sendSymptom(val),
                        decoration: const InputDecoration(
                          hintText: 'Describe symptoms (e.g. fever, headache)...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D47A1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () => _sendSymptom(_inputController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessageBubble(String message, {required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF0D47A1) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: isMe ? [] : [BoxShadow(color: Colors.grey.shade200, blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Text(
          message,
          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildAnalyzingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00B8D4)),
            ),
            SizedBox(width: 12),
            Text('Analyzing clinical symptoms...', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTriageCard(Map<String, dynamic> item) {
    final Color riskColor = item['riskColor'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: riskColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: riskColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['riskLevel'],
                  style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item['summary'],
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Red Flags: ${item['redFlags']}',
                    style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DoctorListScreen()),
              );
            },
            icon: const Icon(Icons.medical_services, color: Colors.white, size: 18),
            label: Text(
              'Book ${item['specialist']}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
