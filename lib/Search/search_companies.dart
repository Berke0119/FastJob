import 'package:berkeserinfinal/Widgets/all_companies_widget.dart';
import 'package:berkeserinfinal/Widgets/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AllWorkersScreen extends StatefulWidget {
  @override
  State<AllWorkersScreen> createState() => _AllWorkersScreenState();
}

class _AllWorkersScreenState extends State<AllWorkersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = 'Search query';

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autocorrect: true,
      decoration: const InputDecoration(
        hintText: 'Search for companies...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: (query) => _updateSearchQuery(query),
    );
  }

  List<Widget> _buildActions() {
    return <Widget>[
      IconButton(
        onPressed: () {
          _clearSearch();
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      searchQuery = 'Search query';
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
        colors: [Colors.deepOrange.shade300, Colors.blueAccent],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      )),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: BottomNavigationBarForApp(indexNumber: 1),
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                colors: [Colors.deepOrange.shade300, Colors.blueAccent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )),
            ),
            title: _buildSearchField(),
            actions: _buildActions(),
            automaticallyImplyLeading: false,
          ),
          body: StreamBuilder(
            stream: searchQuery.isEmpty || searchQuery == 'Search query'
                ? FirebaseFirestore.instance.collection('users').snapshots()
                : FirebaseFirestore.instance
                    .collection('users')
                    .where('name', isEqualTo: searchQuery)
                    .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // Snapshot'taki verileri al
              final documents = snapshot.data!.docs;

              return ListView.builder(
                itemCount: documents.length, // Eleman sayısını belirle
                itemBuilder: (context, index) {
                  final document = documents[index];

                  return AllWorkersWidget(
                    userId: document['id'],
                    userName: document['name'],
                    userEmail: document['email'],
                    phoneNumber: document['phone'],
                    userImageUrl: document['imageUrl'],
                  );
                },
              );
            },
          )),
    );
  }
}
