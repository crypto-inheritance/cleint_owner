import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inheritance Beneficiary',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Inheritance: Owner / Signatory'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class CallResult {
  late bool success;
  late String result;

  CallResult(this.success, this.result);
  @override
  String toString() {
    return "TransactionResult:::\t success: $success\t result: $result";
  }
}

class TransactionSC {
   String signatory;
   int amount;
   bool approved;
   int approvalCount;
   List<String> approvedBy;

  TransactionSC(this.signatory, this.amount, this.approved, this.approvalCount, this.approvedBy);
  @override
  String toString() {
    return "Transaction:::\t signatory: $signatory\t amount: $amount\t approved: $approved\t approvalCount: $approvalCount\t approvedBy: $approvedBy";
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late Client httpClient;
  late Web3Client ethereumClient;
  TextEditingController controllerTxAmountOrID = TextEditingController();
  TextEditingController controllerSigAccount = TextEditingController();
  TextEditingController controllerSigWeight = TextEditingController();
  TextEditingController controllerInheritanceThreshold = TextEditingController();
  TextEditingController controllerInheritanceDeadline = TextEditingController();
  TextEditingController controllerTxApprovalThreshold = TextEditingController();
  TextEditingController controllerWalletAddress = TextEditingController();
  TextEditingController controllerOwnerPK = TextEditingController();

  String private_key_1 = '1';
  String private_key_2 = '2';
  String private_key_3 = '3';
  String private_key_4 = '4';

  String public_address_1 = '1';
  String public_address_2 = '2';
  String public_address_3 = '3';
  String public_address_4 = '4';
  String selectedAddress = "";
  String governmentAddress = "";
  String selectedWeight = "";
  String selectedAddressForSender = "";
  String signatoryCallResponse = "The result of call will be displayed here";
  String transactionCallResponse = "The result of call will be displayed here";

  String ethereumClientUrl =
      'https://sepolia.infura.io/v3/...';
  String contractAddress = "0x542d67E8d5eCCF1919639366EF9aF312403Bc493";
  String contractName = "Inheritance";
  // String private_key = "";

  int balance = 0;
  int numOfSignatories = 0;
  int numOfBeneficiaries = 0;
  bool isInheritanceRequestActive = false;
  bool isInheritanceDeadlineActive = false;
  String inheritanceStatus = "Not Active";
  int lastTransactionTime = 0;
  int inactivityThreshold = 0;
  int inheritanceDeadline = 0;
  int inheritanceRequestTime = 0;
  int approvalThreshold = 0;
  bool loading = false;
  String lastTransactionResult = "";
  String lastTransactionResultDefault = "No request yet...";
  bool lastTransactionSuccess = false;
  List<TransactionSC> transactions = [];
  int totalTransactions = 0;
  int approvedTransactions = 0;

  void resetVariables(){
    balance = 0;
    numOfSignatories = 0;
    numOfBeneficiaries = 0;
    isInheritanceRequestActive = false;
    isInheritanceDeadlineActive = false;
    inheritanceStatus = "Not Active";
    lastTransactionTime = 0;
    inactivityThreshold = 0;
    inheritanceDeadline = 0;
    inheritanceRequestTime = 0;
    approvalThreshold = 0;
    loading = false;
    lastTransactionResult = "";
    lastTransactionResultDefault = "No request yet...";
    lastTransactionSuccess = false;
    transactions = [];
    totalTransactions = 0;
    approvedTransactions = 0;

    selectedAddress = "";
    selectedWeight = "";
    selectedAddressForSender = "";
    signatoryCallResponse = "The result of call will be displayed here";
    transactionCallResponse = "The result of call will be displayed here";

    controllerSigWeight.text = "";
    controllerSigAccount.text = "";
    controllerInheritanceDeadline.text = "";
    controllerInheritanceThreshold.text = "";
  }

  String getSavedAddress(String value){
    switch (value){
      case "Account 1":
        return public_address_1;
      case "Account 2":
        return public_address_2;
      case "Account 3":
        return public_address_3;
      case "Account 4":
        return public_address_4;
      default:
        return "";
    }
  }

  String getSavedPrivateKey(String value){
    switch (value){
      case "Account 1":
        return private_key_1;
      case "Account 2":
        return private_key_2;
      case "Account 3":
        return private_key_3;
      case "Account 4":
        return private_key_4;
      default:
        return "";
    }

  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    DeployedContract contract = await getContract();
    ContractFunction function = contract.function(functionName);
    List<dynamic> result = await ethereumClient.call(
        contract: contract, function: function, params: args);
    return result;
  }


  Future<CallResult> transaction(String functionName, String privateKey, List<dynamic> args) async {
    try {
      EthPrivateKey credential = EthPrivateKey.fromHex(privateKey);
      // EthPrivateKey credential = EthPrivateKey.fromHex(privateKey);
      DeployedContract contract = await getContract();
      ContractFunction function = contract.function(functionName);
      dynamic result = await ethereumClient.sendTransaction(
        credential,
        Transaction.callContract(
          contract: contract,
          function: function,
          parameters: args,
        ),
        fetchChainIdFromNetworkId: true,
        chainId: null,
      );
      return CallResult(true, result);
    } catch(e){
      print('call function has error ::::: $e');
      return CallResult(false, e.toString());
    }
  }

  Future<DeployedContract> getContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    // String contractAddress = "0xe51a1923ACc22d45245e88b83838f4f93d529c29";

    DeployedContract contract = DeployedContract(
      ContractAbi.fromJson(abi, contractName),
      EthereumAddress.fromHex(contractAddress),
    );

    return contract;
  }

  Future<void> loadInformation() async {

    // List<dynamic> result6 = await query('lastTransactionTime', []);
    // List<dynamic> result7 = await query('inactivityThreshold', []);
    // List<dynamic> result8 = await query('inheritanceDeadline', []);
    // List<dynamic> result9 = await query('inheritanceRequestTime', []);
    // lastTransactionTime = int.parse(result6[0].toString());
    // inactivityThreshold = int.parse(result7[0].toString());
    // inheritanceDeadline = int.parse(result8[0].toString());
    // inheritanceRequestTime = int.parse(result9[0].toString());
    resetVariables();
    loading = true;
    setState(() {});
    List<dynamic> result1 = await query('balance', []);
    List<dynamic> result2 = await query('approvedSignatoryCount', []);
    List<dynamic> result3 = await query('getSignatoryAddresses', []);
    List<dynamic> result4 = await query('inheritanceRequestActive', []);
    List<dynamic> result5 = await query('inheritanceDeadlineActive', []);
    List<dynamic> result10 = await query('approvalThreshold', []);
    // List<dynamic> result11 = await query('transactions', []);
    balance = int.parse(result1[0].toString());
    numOfSignatories = int.parse(result2[0].toString());
    numOfBeneficiaries = result3[0].length + 1 - numOfSignatories;

    isInheritanceRequestActive = result4[0];
    isInheritanceDeadlineActive = result5[0];
    if (!isInheritanceRequestActive && !isInheritanceDeadlineActive){
      inheritanceStatus = "Not Active";
    } else if (isInheritanceRequestActive && isInheritanceDeadlineActive){
      inheritanceStatus = "Active";
    }else if (!isInheritanceRequestActive && isInheritanceDeadlineActive){
      inheritanceStatus = "Canceled";
    }else if (isInheritanceRequestActive && !isInheritanceDeadlineActive){
      inheritanceStatus = "Approved";
    }
    approvalThreshold = int.parse(result10[0].toString());
    // for (int i = 0; i < result11[0].length; i++){
    //   print('Result: ${result11[0][i]}');
    // }
    loading = false;
    setState(() {});
  }

  Future<void> addSignatory(String privateKey, String signatory, String weight) async {
    EthereumAddress add = EthereumAddress.fromHex(signatory);
    var result = await transaction("addSignatory", privateKey, [add, BigInt.parse(weight)]);
    if(result.success){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("New Signatory Added"),
      ));
      loadInformation();
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Request Failed!!!"),
      ));
    }
    signatoryCallResponse = result.result;
    print(signatoryCallResponse);
    print("Signatory Added");
    setState(() {});
  }

  Future<void> removeSignatory(String privateKey, String signatory) async {
    EthereumAddress add = EthereumAddress.fromHex(signatory);
    var result = await transaction("removeSignatory", privateKey, [add]);
    if(result.success){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Signatory removed"),
      ));
      loadInformation();
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Request Failed!!!"),
      ));
    }
    signatoryCallResponse = result.result;
    print(signatoryCallResponse);
    print("Signatory Removed");
    setState(() {});
  }

  Future<void> approveSignatory(String privateKey, String signatory, String weight) async {
    EthereumAddress add = EthereumAddress.fromHex(signatory);
    var result = await transaction("approveSignatory", privateKey, [add, BigInt.parse(weight)]);
    if(result.success){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("New Signatory Approved"),
      ));
      loadInformation();
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Request Failed!!!"),
      ));
    }
    signatoryCallResponse = result.result;
    print(signatoryCallResponse);
    print("Signatory Added");
    setState(() {});
  }

  Future<void> setInactivityThreshold(String privateKey, String days) async {
    var result = await transaction("setInactivityThreshold", privateKey, [BigInt.parse(days) * BigInt.from(86400)]);
    if(result.success){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Inactivity Threshold Updated"),
      ));
      loadInformation();
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Request Failed!!!"),
      ));
    }
    signatoryCallResponse = result.result;
    print(signatoryCallResponse);
    print("Signatory Added");
    setState(() {});
  }

  Future<void> setInheritanceDeadline(String privateKey, String days) async {
    var result = await transaction("setInheritanceDeadline", privateKey, [BigInt.parse(days) * BigInt.from(86400)]);
    if(result.success){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Inheritance Deadline Updated"),
      ));
      loadInformation();
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Request Failed!!!"),
      ));
    }
    signatoryCallResponse = result.result;
    print(signatoryCallResponse);
    print("Signatory Added");
    setState(() {});
  }

  Future<void> setGovernmentAddress(String privateKey, String gov) async {
    EthereumAddress add = EthereumAddress.fromHex(gov);
    var result = await transaction("setGovernmentAddress", privateKey, [add]);
    if(result.success){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Government Address Updated"),
      ));
      loadInformation();
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Request Failed!!!"),
      ));
    }
    signatoryCallResponse = result.result;
    print(signatoryCallResponse);
    print("Government Address Updated");
    setState(() {});
  }

  Future<void> setApprovalThreshold(String privateKey, String threshold) async {
    var result = await transaction("setApprovalThreshold", privateKey, [BigInt.parse(threshold)]);
    if(result.success){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Transaction Approval Threshold Updated"),
      ));
      loadInformation();
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Request Failed!!!"),
      ));
    }
    transactionCallResponse = result.result;
    print(transactionCallResponse);
    print("Transaction Approval Updated");
    setState(() {});
  }

  Future<void> setWalletAddress(String privateKey, String wallet) async {
    EthereumAddress add = EthereumAddress.fromHex(wallet);
    var result = await transaction("setWalletAddress", privateKey, [add]);
    if(result.success){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Wallet Address Updated"),
      ));
      loadInformation();
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Request Failed!!!"),
      ));
    }
    transactionCallResponse = result.result;
    print(transactionCallResponse);
    print("Wallet Address Updated");
    setState(() {});
  }

  Future<void> depositAsset(String privateKey, String value) async {
    var result = await transaction("addBalance", privateKey, [BigInt.parse(value)]);
    if(result.success){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Assets Deposited"),
      ));
      loadInformation();
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Request Failed!!!"),
      ));
    }
    transactionCallResponse = result.result;
    print(transactionCallResponse);
    print("Assets Deposited");
    setState(() {});
  }

  Future<void> requestTransaction(String privateKey, String amount) async {
    var result = await transaction("requestTransaction", privateKey, [BigInt.parse(amount)]);
    if(result.success){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("New Transaction Requested"),
      ));
      loadInformation();
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Request Failed!!!"),
      ));
    }
    transactionCallResponse = result.result;
    print(transactionCallResponse);
    print("New Transaction Requested");
    setState(() {});
  }

  Future<void> approveTransaction(String privateKey, String txID) async {
    var result = await transaction("approveTransaction", privateKey, [BigInt.parse(txID)]);
    if(result.success){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Transaction is approved"),
      ));
      loadInformation();
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Request Failed!!!"),
      ));
    }
    transactionCallResponse = result.result;
    print(transactionCallResponse);
    print("Transaction is approved");
    setState(() {});
  }


  void listenToAddSignatoryEvent() async {

    final contract = await getContract();
    print("Listening to the event...");
    var event = contract.event('SignatoryAdded');
    final subscription = ethereumClient.events(FilterOptions.events(contract: contract, event: event)).listen((event) {
      print("event.toString(): ${event.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("The Owner Added a New Beneficiary"),
      ));
      loadInformation();
    });
  }


  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethereumClient = Web3Client(ethereumClientUrl, httpClient);
    loadInformation();
    // listenToAddSignatoryEvent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            const Text(
              "*** Information ***",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            Container(
              margin: const EdgeInsets.all(15.0),
              padding: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                  border: Border.all(color:  Colors.black)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        "Approved Signatories:",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Balance:",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        loading
                            ? CircularProgressIndicator()
                            : Text(
                          "$numOfSignatories / ${numOfBeneficiaries + numOfSignatories} ($approvalThreshold)",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        loading
                            ? CircularProgressIndicator()
                            : Text(
                          balance.toString(),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                      ]
                  ),

                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.all(15.0),
              padding: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.red)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Sender Private Key",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      Flexible(

                        child: TextField(
                          controller: controllerOwnerPK,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(label: Text('Enter private key')),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      DropdownButton<String>(
                        hint: const Text('Enter from saved'),
                        value: selectedAddressForSender.isNotEmpty ? selectedAddressForSender : null,
                        items: <String>['Account 1', 'Account 2', 'Account 3', 'Account 4'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedAddressForSender = value!;
                            controllerOwnerPK.text = getSavedPrivateKey(value);
                          });
                        },
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 30,
            ),
            const Text(
              "*** Signatory Management ***",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            Container(
              margin: const EdgeInsets.all(15.0),
              padding: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      Flexible(

                        child: TextField(
                          controller: controllerSigAccount,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(label: Text('signatory address')),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      DropdownButton<String>(
                        hint: const Text('Saved Accounts'),
                        value: selectedAddress.isNotEmpty ? selectedAddress : null,
                        items: <String>['Account 1', 'Account 2', 'Account 3', 'Account 4'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedAddress = value!;
                            controllerSigAccount.text = getSavedAddress(value);
                          });
                        },
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      Flexible(

                        child: TextField(
                          controller: controllerSigWeight,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(label: Text('signatory share')),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      DropdownButton<String>(
                        hint: const Text('Direct Input'),
                        value: selectedWeight.isNotEmpty ? selectedWeight : null,
                        items: <String>['10%', '20%', '30%', '40%', '50%', '60%', '70%', '80%', '90%', '100%'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedWeight = value!;
                            controllerSigWeight.text = value.split('%')[0];
                          });
                        },
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        child: const Text('Add New'),
                        onPressed: () => addSignatory(controllerOwnerPK.text, controllerSigAccount.text, controllerSigWeight.text),
                      ),
                      ElevatedButton(
                        child: const Text('Approve'),
                        onPressed: () => approveSignatory(controllerOwnerPK.text, controllerSigAccount.text, controllerSigWeight.text),
                      ),
                      ElevatedButton(
                        child: const Text('Remove'),
                        onPressed: () => removeSignatory(controllerOwnerPK.text, controllerSigAccount.text),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Divider(
                      color: Colors.black
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    signatoryCallResponse,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w200),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Divider(
                      color: Colors.black
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      Flexible(

                        child: TextField(
                          controller: controllerInheritanceThreshold,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(label: Text('Days')),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      ElevatedButton(
                        child: const Text('Set Inactivity Threshold'),
                        onPressed: () => setInactivityThreshold(controllerOwnerPK.text, controllerInheritanceThreshold.text),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      Flexible(

                        child: TextField(
                          controller: controllerInheritanceDeadline,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(label: Text('Days')),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      ElevatedButton(
                        child: const Text('Set Inheritance Deadline'),
                        onPressed: () => setInheritanceDeadline(controllerOwnerPK.text, controllerInheritanceDeadline.text),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      DropdownButton<String>(
                        hint: const Text('Saved Accounts'),
                        value: governmentAddress.isNotEmpty ? governmentAddress : null,
                        items: <String>['Account 1', 'Account 2', 'Account 3', 'Account 4'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            governmentAddress = value!;
                            // controllerSigAccount.text = getSavedAddress(value);
                          });
                        },
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      ElevatedButton(
                        child: const Text('Set Gov. Address'),
                        onPressed: () => setGovernmentAddress(controllerOwnerPK.text, getSavedAddress(governmentAddress)),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 30,
            ),
            const Text(
              "*** Transaction Management ***",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            Container(
              margin: const EdgeInsets.all(15.0),
              padding: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      Flexible(
                        child: TextField(
                          controller: controllerTxAmountOrID,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(label: Text('Transaction amount / ID')),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        child: const Text('Deposit'),
                        onPressed: () => depositAsset(controllerOwnerPK.text, controllerTxAmountOrID.text),
                      ),
                      ElevatedButton(
                        child: const Text('Request'),
                        onPressed: () => requestTransaction(controllerOwnerPK.text, controllerTxAmountOrID.text),
                      ),
                      ElevatedButton(
                        child: const Text('Approve'),
                        onPressed: () => approveTransaction(controllerOwnerPK.text, controllerTxAmountOrID.text),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Divider(
                      color: Colors.black
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    transactionCallResponse,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w200),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Divider(
                      color: Colors.black
                  ),
                  const SizedBox(
                    height: 10,
                  ),

                  const SizedBox(
                    width: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      Flexible(

                        child: TextField(
                          controller: controllerTxApprovalThreshold,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(label: Text('N / M')),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      ElevatedButton(
                        child: const Text('Set Minimum Approval'),
                        onPressed: () => setApprovalThreshold(controllerOwnerPK.text, controllerTxApprovalThreshold.text),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      Flexible(

                        child: TextField(
                          controller: controllerWalletAddress,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(label: Text('Wallet')),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      ElevatedButton(
                        child: const Text('Set Wallet Address'),
                        onPressed: () => setWalletAddress(controllerOwnerPK.text, controllerWalletAddress.text),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 70,
            ),
          ],
        )
      ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton(
          onPressed: loadInformation,
          tooltip: 'Increment',
          child: const Icon(Icons.refresh),
        ),
    );
  }
}
