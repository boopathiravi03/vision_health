import 'package:flutter/material.dart';

import '../../services/health_assistant_service.dart';

class HealthAssistantScreen extends StatefulWidget {
  const HealthAssistantScreen({super.key});

  @override
  State<HealthAssistantScreen> createState() =>
      _HealthAssistantScreenState();
}

class _HealthAssistantScreenState
    extends State<HealthAssistantScreen> {
  final TextEditingController _queryController =
      TextEditingController();

  String _language = 'English';
  bool _loading = false;
  String? _response;
  String? _error;

  Future<void> _ask() async {
    final query = _queryController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _error = 'Please enter a question.';
      });

      return;
    }

    setState(() {
      _loading = true;
      _response = null;
      _error = null;
    });

    try {
      final result =
          await HealthAssistantService.ask(
        query: query,
        language: _language,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _response =
            result['response']?.toString() ??
                'No response received.';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('Health Assistant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inputCard(),
            const SizedBox(height: 16),
            if (_error != null) _errorCard(),
            if (_response != null) _responseCard(),
          ],
        ),
      ),
    );
  }

  Widget _inputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ask a health question',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _queryController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Example: What care should be given for mild fever?',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF087F73),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              DropdownButton<String>(
                value: _language,
                items: const [
                  DropdownMenuItem(
                    value: 'English',
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: 'Tamil',
                    child: Text('Tamil'),
                  ),
                  DropdownMenuItem(
                    value: 'Hindi',
                    child: Text('Hindi'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _language = value;
                  });
                },
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _loading ? null : _ask,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _loading ? 'ASKING...' : 'ASK',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _responseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Color(0xFF087F73),
              ),
              SizedBox(width: 8),
              Text(
                'Assistant Response',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _response!,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        _error!,
        style: TextStyle(color: Colors.red.shade800),
      ),
    );
  }
}
