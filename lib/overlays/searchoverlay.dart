import 'package:flutter/material.dart';
import 'package:waterfilternet/services/woocommerce_api.dart';
import '../models/product.dart';

class SearchOverlay extends StatefulWidget {
  final Widget Function({required Function(String) onSearch}) searchField;

  const SearchOverlay({Key? key, required this.searchField}) : super(key: key);

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final WooCommerceAPI api = WooCommerceAPI();
  List<Product> _results = [];
  bool _isLoading = false;

  void _search(String keyword) async {
    if (!mounted) return; // ✅ Prevent running if widget is disposed

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await api.fetchProducts(search: keyword);
      if (!mounted) return;

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint("Search error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          widget.searchField(onSearch: _search), // ✅ Uses HomePage search bar
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final product = _results[index];
                        return ListTile(
                          leading:
                              product.images.isNotEmpty
                                  ? Image.network(
                                    product.images.first,
                                    width: 50,
                                  )
                                  : null,
                          title: Text(product.name),
                          subtitle: Text("${product.price}€"),
                          onTap: () {
                            // Navigate to product page (if needed)
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
