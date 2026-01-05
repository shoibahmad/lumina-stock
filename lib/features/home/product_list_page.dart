import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../profile/profile_page.dart';
import '../auth/login_page.dart';
import '../admin/add_product_page.dart';
import '../admin/barcode_scanner_screen.dart';
import '../admin/analytics_page.dart';
import '../../models/sale_transaction.dart';
import 'stat_item.dart'; 


class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  String _searchQuery = '';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  late Stream<QuerySnapshot> _productsStream;

  @override
  void initState() {
    super.initState();
    // Initialize stream ONLY ONCE to enable persistent connection
    _productsStream = FirebaseFirestore.instance.collection('product').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bool isAdmin = authService.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lumina',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black54),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                     TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                     TextButton(
                       onPressed: () {
                          Navigator.pop(context); // Close dialog
                          authService.signOut();
                          Navigator.pushAndRemoveUntil(
                            context, 
                            MaterialPageRoute(builder: (_) => const LoginPage()), 
                            (route) => false
                          );
                       }, 
                       child: const Text('Logout', style: TextStyle(color: AppTheme.errorRed))
                     ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _productsStream, // Use the persistent stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allDocs = snapshot.data?.docs ?? [];
          
          // 1. Extract Categories for Filter Chips
          final Set<String> categories = allDocs
              .map((doc) => (doc.data() as Map<String, dynamic>)['category'] as String? ?? 'Other')
              .toSet();
          final List<String> sortedCategories = categories.toList()..sort();

          // 2. Filter Products
          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] as String).toLowerCase();
            final category = data['category'] as String? ?? 'Other';
            
            final barcode = data['barcode'] as String? ?? '';
            
            final matchesSearch = name.contains(_searchQuery.toLowerCase()) || 
                                  barcode.contains(_searchQuery);
            final matchesCategory = _selectedCategory == null || category == _selectedCategory;

            return matchesSearch && matchesCategory;
          }).toList();

          // Stats (based on total, not filtered)
          int productCount = allDocs.length;
          
          return CustomScrollView(
            slivers: [
              // Admin Dashboard
              if (isAdmin)
                SliverToBoxAdapter(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (context, userSnapshot) {
                      final int userCount = userSnapshot.data?.docs.length ?? 0;
                      return Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.primaryBlue, AppTheme.primaryAccent],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                             BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0,10))
                          ],
                        ),
                        child: Column(
                          children: [
                            Text('Admin Overview', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                StatItem(icon: Icons.people, label: 'Total Users', value: '$userCount'),
                                StatItem(icon: Icons.inventory, label: 'Products', value: '$productCount'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsPage()));
                              },
                              icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryBlue),
                              label: const Text('View Analytics', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryBlue,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            )
                          ],
                        ),
                      );
                    }
                  ),
                ),

              // Search Bar & Categories
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search products or scan barcode...',
                          prefixIcon: const Icon(Icons.search, color:  AppTheme.primaryBlue),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
                                );
                                if (result != null && result is String) {
                                  setState(() {
                                    _searchQuery = result;
                                    _searchController.text = result;
                                  });
                                }
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Categories
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ActionChip(
                              label: const Text('All'),
                              backgroundColor: _selectedCategory == null ? AppTheme.primaryBlue : Colors.white,
                              labelStyle: TextStyle(
                                color: _selectedCategory == null ? Colors.white : Colors.black87,
                                fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ...sortedCategories.map((category) {
                              final isSelected = _selectedCategory == category;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  label: Text(category),
                                  backgroundColor: isSelected ? AppTheme.primaryBlue : Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedCategory = isSelected ? null : category;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.60,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = filteredDocs[index].data() as Map<String, dynamic>;
                      final product = Product.fromMap(data, filteredDocs[index].id);
                      return ProductCard(product: product, isAdmin: isAdmin);
                    },
                    childCount: filteredDocs.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        }
      ),
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
        },
        label: const Text('Add Product'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ) : null,
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isAdmin;

  const ProductCard({super.key, required this.product, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Optimize layout
          children: [
            // Image Section (Aspect Ratio 4:3 roughly)
            AspectRatio(
              aspectRatio: 1.45,
              child: Stack(
                children: [
                   Hero(
                    tag: product.id,
                     child: Image.network(
                       product.imageUrl,
                       width: double.infinity,
                       height: double.infinity,
                       fit: BoxFit.cover,
                       errorBuilder: (context, error, stackTrace) =>
                           Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                     ),
                   ),
                   // Category Tag
                   Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Text(
                        product.category.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  // Stock Tag
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.quantity > 0 ? AppTheme.secondaryGreen : AppTheme.errorRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.quantity > 0 ? '${product.quantity} in stock' : 'Out of Stock',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.3,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 8),
                    
                    // Pricing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buy: ${formatCurrency.format(product.buyingPrice)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              formatCurrency.format(product.sellingPrice),
                              style: GoogleFonts.poppins(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        // Actions
                        if (isAdmin) 
                          Row(
                            children: [
                              _ActionButton(
                                icon: Icons.edit_outlined, 
                                color: AppTheme.primaryBlue, 
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductPage(productToEdit: product)))
                              ),
                              const SizedBox(width: 8),
                              _ActionButton(
                                icon: Icons.delete_outline, 
                                color: AppTheme.errorRed, 
                                onTap: () async {
                                   // Delete logic repeated - can refactor later but inline is ok
                                   // ... (Keep existing logic short for now) or call helper?
                                   // Since I'm replacing content, I must implement it or keep it.
                                   // Let's use the EXISTING logic block but compact.
                                   _confirmDelete(context);
                                }
                              ),
                            ],
                          )
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (isAdmin)
               Padding(
                 padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                 child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: product.quantity > 0 ? () => _showSellDialog(context) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Sell Item', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                 ),
               ),
          ],
        ),
      );
    }
  
    // Helpers
    Future<void> _confirmDelete(BuildContext context) async {
       final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: const Text('Are you sure?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirmed == true) {
          await FirebaseFirestore.instance.collection('product').doc(product.id).delete();
        }
    }

    Future<void> _showSellDialog(BuildContext context) async {
    final quantityController = TextEditingController(text: '1');
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sell Product'),
          content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                Text('Sell ${product.name}'),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                )
             ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: () async {
                 final qty = int.tryParse(quantityController.text) ?? 1;
                 if (qty <= 0) return;
                 
                 if (qty > product.quantity) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock!')));
                    return;
                 }

                 Navigator.pop(context); // Close dialog

                 try {
                    await FirebaseFirestore.instance.runTransaction((transaction) async {
                       final productRef = FirebaseFirestore.instance.collection('product').doc(product.id);
                       final productSnapshot = await transaction.get(productRef);
                       
                       if (!productSnapshot.exists) throw Exception("Product not found");
                       
                       final currentQty = (productSnapshot.data() as Map<String, dynamic>)['quantity'] as int? ?? 0;
                       if (currentQty < qty) throw Exception("Not enough stock"); // Double check

                       // Decrement Stock
                       transaction.update(productRef, {'quantity': currentQty - qty});

                       // Add Transaction
                       final sale = SaleTransaction(
                         id: '', // Generated
                         productId: product.id,
                         productName: product.name,
                         category: product.category,
                         quantity: qty,
                         totalPrice: product.sellingPrice * qty,
                         totalProfit: product.profit * qty,
                         date: DateTime.now(),
                       );
                       
                       final saleRef = FirebaseFirestore.instance.collection('transactions').doc();
                       transaction.set(saleRef, sale.toMap());
                    });
                    
                    if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sale Recorded!'), backgroundColor: AppTheme.secondaryGreen)
                        );
                    }
                 } catch (e) {
                    if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed)
                        );
                    }
                 }
              }, 
              child: const Text('Confirm Sale'),
            ),
          ],
        );
      }
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

