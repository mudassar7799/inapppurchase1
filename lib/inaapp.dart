
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import'dart:io';

final String testID ='android.test.purchased';

class MarketScreen extends StatefulWidget {
  createState() => _MarketScreenState();
}

class _MarketScreenState extends State< MarketScreen> {

  InAppPurchaseConnection _iap = InAppPurchaseConnection.instance;
  bool _available = true;
  List<ProductDetails> _products =[];

  List<PurchaseDetails> _purchases =[];

  StreamSubscription _subscription;

  int _credits =0;

  @override
  void initState() {
    _initialize();
    super.initState();

  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }


  void _initialize() async{
    _available = await _iap.isAvailable();
    if(_available){
      await _getProducts();
      await _getPastPurchases();

      //List<Future> futures =[_getProducts(), _getPastPurchase()];
      // await Future.wait(futures);
      _verifyPurchase();

      _subscription = _iap.purchaseUpdatedStream.listen((data)=> setState((){
        print("New Purchase");
        _purchases.addAll(data);
        _verifyPurchase();

      }));

    }

  }
  Future<void> _getProducts() async{
    Set<String> ids = Set.from([testID]);
    ProductDetailsResponse response =await _iap.queryProductDetails(ids);

    setState((){
      _products = response.productDetails;
    });
  }


  Future <void> _getPastPurchases() async{
    QueryPurchaseDetailsResponse response =await _iap.queryPastPurchases();
    for( PurchaseDetails purchase in response.pastPurchases){
      if (Platform.isIOS){
        _iap.completePurchase(purchase);
      }
    }

    setState((){
      _purchases = response.pastPurchases;
    });
  }

  PurchaseDetails _hasPurchased(String productID){
    return _purchases. firstWhere((purchase)=> purchase.productID == productID, orElse: () => null);

  }


  void _verifyPurchase(){
    PurchaseDetails purchase = _hasPurchased(testID);


    if (purchase != null && purchase.status == PurchaseStatus.purchased){
      _credits =10;

    }

  }

  void _buyProduct(ProductDetails prod){
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
//_iap.buyNonConsumable(purchaseParam:purchaseParam);
    _iap.buyConsumable(purchaseParam:purchaseParam, autoConsume: false);

  }

  void _spendCredits(PurchaseDetails purchase) async {
    setState((){
      _credits--;
    });

    if (_credits == 0){
      var  res = await _iap.consumePurchase(purchase);
      await _getPastPurchases();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        title: Text(_available ? 'Open for Business': 'Not Available'),
      ),
      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[



            for(var prod in _products)
              if (_hasPurchased(prod.id) != null)
                ...[
                  Text( '$_credits', style: TextStyle(fontSize: 60),),
                  FlatButton(
                    child: Text('consume'),
                    color: Colors.cyanAccent,
                    onPressed: ()=> _spendCredits(_hasPurchased(prod.id)),
                  ),
                ]
              else
                ... [
                  Text(prod.title, style: Theme.of(context).textTheme.headline),
                  Text(prod.description),
                  Text(prod.price, style: TextStyle(color: Colors.cyanAccent, fontSize: 60),),
                  FlatButton(
                    child: Text('Buy it'),
                    color: Colors.cyanAccent,
                    onPressed: () => _buyProduct(prod),

                  ),

                ],



          ],
        ),
      ),

    );

  }


}
