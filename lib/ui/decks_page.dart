import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:manage_learning/ui/blogs/blog_category_screen.dart';
import 'package:manage_learning/ui/blogs_create.dart';
import 'package:manage_learning/ui/category_screen_new.dart';

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
    setState(() {
      _tabController.index = 0; // Switch to Decks tab
    });
  }

  void _showAddBlog() {
    setState(() {
      _tabController.index = 1; // Switch to Blogs tab
    });
    Navigator.of(context).pushNamed('/blog-updates', arguments: BlogData());
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
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.of(context).pushNamed('/accounts');
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
          CategoryScreenNew(),
          BlogCategoryScreen(),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        renderOverlay: false,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.note_add),
            label: 'Add Deck',
            onTap: _showAddCards,
          ),
          SpeedDialChild(
            child: const Icon(Icons.article),
            label: 'Add Blog',
            onTap: _showAddBlog,
          ),
        ],
      ),
    );
  }
}
