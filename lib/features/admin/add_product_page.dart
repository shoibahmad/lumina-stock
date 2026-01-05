import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import 'package:dotted_border/dotted_border.dart';
import 'barcode_scanner_screen.dart';

class AddProductPage extends StatefulWidget {
  final Product? productToEdit;
  const AddProductPage({super.key, this.productToEdit});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _buyingPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _barcodeController;
  
  XFile? _selectedImage; // Changed to XFile
  String? _existingImageUrl; // For editing
  bool _isUploading = false;
  
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _buyingPriceController = TextEditingController(text: p?.buyingPrice.toString() ?? '');
    _sellingPriceController = TextEditingController(text: p?.sellingPrice.toString() ?? '');
    _quantityController = TextEditingController(text: p?.quantity.toString() ?? '0');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _existingImageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await _cloudinaryService.pickImage(ImageSource.gallery);
                  if (file != null) {
                    setState(() {
                      _selectedImage = file;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await _cloudinaryService.pickImage(ImageSource.camera);
                  if (file != null) {
                    setState(() {
                      _selectedImage = file;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (result != null && result is String) {
      if (!mounted) return; // Check mounted
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if we have an image (either new one selected or existing one)
    if (_selectedImage == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product image')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String imageUrl;
      
      // 1. Upload Image to Cloudinary if a new one is selected
      if (_selectedImage != null) {
        final uploadedUrl = await _cloudinaryService.uploadImage(_selectedImage!);
        if (uploadedUrl == null) {
          throw Exception('Image upload failed');
        }
        imageUrl = uploadedUrl;
        debugPrint('Admin: Image uploaded. URL: $imageUrl');
      } else {
        // Use existing image
        imageUrl = _existingImageUrl!;
      }

      // 2. Create Product Object
      final product = Product(
        id: widget.productToEdit?.id ?? '', // Use existing ID if editing
        name: _nameController.text,
        category: _categoryController.text,
        buyingPrice: double.tryParse(_buyingPriceController.text) ?? 0.0,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
        imageUrl: imageUrl,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        barcode: _barcodeController.text.isNotEmpty ? _barcodeController.text : null,
      );

      debugPrint('Admin: Saving to Firestore...');
      
      // 3. Save to Firestore (Update or Add)
      if (widget.productToEdit != null) {
         await FirebaseFirestore.instance.collection('product').doc(widget.productToEdit!.id).update(product.toMap());
         debugPrint('Admin: Updated Firestore successfully!');
      } else {
         await FirebaseFirestore.instance.collection('product').add(product.toMap());
         debugPrint('Admin: Added to Firestore successfully!');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.productToEdit != null ? 'Product Updated Successfully!' : 'Product Added Successfully!'), 
            backgroundColor: AppTheme.secondaryGreen
          ),
        );
        debugPrint('Admin: Navigating back...');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productToEdit != null ? 'Edit Product' : 'Add New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  padding: const EdgeInsets.all(6),
                  color: Colors.grey.shade400,
                  strokeWidth: 1,
                  dashPattern: const [8, 4],
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade50,
                      child: _selectedImage != null
                          ? (kIsWeb 
                              ? Image.network(_selectedImage!.path, fit: BoxFit.cover) 
                              : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                          : (_existingImageUrl != null 
                              ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 50, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to upload product image',
                                      style: TextStyle(color: Colors.grey.shade500),
                                    ),
                                  ],
                                )),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _nameController,
                decoration: AppTheme.inputDecoration('Product Name', Icons.shopping_bag_outlined),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _categoryController,
                decoration: AppTheme.inputDecoration('Category', Icons.category_outlined),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buyingPriceController,
                      keyboardType: TextInputType.number,
                      decoration: AppTheme.inputDecoration('Buying Price', Icons.currency_rupee),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: TextInputType.number,
                      decoration: AppTheme.inputDecoration('Selling Price', Icons.currency_rupee),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: AppTheme.inputDecoration('Quantity', Icons.inventory_2_outlined),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: AppTheme.inputDecoration('Barcode (Optional)', Icons.qr_code),
                    ),
                   ),
                   const SizedBox(width: 8),
                   IconButton.filled(
                     onPressed: _scanBarcode, 
                     icon: const Icon(Icons.qr_code_scanner),
                     style: IconButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                   )
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveProduct,
                  style: AppTheme.primaryButtonStyle,
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.productToEdit != null ? 'Update Product' : 'Save Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
