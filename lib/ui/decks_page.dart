import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manage_learning/ui/blogs_create.dart';
import 'package:manage_learning/ui/blogs_widget.dart';
import 'package:manage_learning/ui/decs_widget.dart';

class DecksPage extends StatefulWidget {
  const DecksPage({super.key});

  @override
  _DecksPageWidgetState createState() => _DecksPageWidgetState();
}

class _DecksPageWidgetState extends State<DecksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCards() {
    Navigator.of(context).pushNamed('/addcards');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Decks'),
            Tab(text: 'Blogs'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () {
              Navigator.of(context).pushNamed('/smart-deck');
            },
          ),
          IconButton(
            icon: const Icon(Icons.article),
            onPressed: () {
              Navigator.of(context)
                  .pushNamed('/blog-updates', arguments: BlogData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DecksWidget(),
          BlogsWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCards,
        tooltip: 'Add Deck',
        child: const Icon(Icons.add),
      ),
    );
  }
}
