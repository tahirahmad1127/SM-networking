import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';

class AnimatedSearchAppBar extends StatefulWidget {
  final String title;
  final void Function(String) onSearch;
  final VoidCallback onCancel;

  const AnimatedSearchAppBar({
    super.key,
    required this.title,
    required this.onSearch,
    required this.onCancel,
  });

  @override
  State<AnimatedSearchAppBar> createState() => _AnimatedSearchAppBarState();
}

class _AnimatedSearchAppBarState extends State<AnimatedSearchAppBar> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    widget.onCancel();
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      title: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        firstChild: Text(widget.title),
        secondChild: TextField(
          controller: _searchController,
          decoration: InputDecoration(
              hintText: 'Search by Shop Name',
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(10),
              ),
              hintStyle: TextStyle(color: FrontendConfigs.kAuthTextColor),
              fillColor: FrontendConfigs.kTextFieldColor,
              filled: true),
          style: TextStyle(color: FrontendConfigs.kAuthTextColor),
          autofocus: true,
          onChanged: widget.onSearch,
        ),
        crossFadeState: _isSearchVisible
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
          onPressed: _toggleSearch,
        ),
      ],
    );
  }
}
