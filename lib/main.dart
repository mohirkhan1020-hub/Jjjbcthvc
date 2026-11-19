import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My To-Do App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TodoScreen(),
    );
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  // টাস্কের লিস্ট রাখার জন্য
  final List<Map<String, dynamic>> _tasks = [];
  // ইনপুট নেওয়ার জন্য কন্ট্রোলার
  final TextEditingController _textController = TextEditingController();

  // নতুন টাস্ক যোগ করার ফাংশন
  void _addTask() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _tasks.add({
          'title': _textController.text,
          'isDone': false, // শুরুতে কাজটি অসম্পূর্ণ থাকবে
        });
      });
      _textController.clear(); // লেখা মুছে ফেলা
    }
  }

  // টাস্ক ডিলিট করার ফাংশন
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'আমার ডেইলি টাস্ক',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // টাস্ক ইনপুট দেওয়ার জায়গা
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'নতুন কাজ লিখুন...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _addTask(), // কিবোর্ড থেকে এন্টার দিলেও যোগ হবে
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    )
                  ),
                  child: const Text('যোগ করুন', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
          
          // টাস্ক লিস্ট দেখানোর জায়গা
          Expanded(
            child: _tasks.isEmpty
                ? const Center(
                    child: Text(
                      'এখনো কোনো কাজ যোগ করা হয়নি!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 2,
                        child: ListTile(
                          leading: Checkbox(
                            value: _tasks[index]['isDone'],
                            activeColor: Colors.deepPurple,
                            onChanged: (bool? value) {
                              setState(() {
                                _tasks[index]['isDone'] = value!;
                              });
                            },
                          ),
                          title: Text(
                            _tasks[index]['title'],
                            style: TextStyle(
                              fontSize: 18,
                              decoration: _tasks[index]['isDone']
                                  ? TextDecoration.lineThrough // কাজ শেষ হলে কাটা দাগ পড়বে
                                  : TextDecoration.none,
                              color: _tasks[index]['isDone'] ? Colors.grey : Colors.black,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTask(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}