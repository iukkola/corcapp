import 'package:flutter/material.dart';

class PaymentsScreen extends StatefulWidget {
  @override
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carbon Credit Payments'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carbon Credits Balance Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco, color: Colors.green, size: 30),
                        SizedBox(width: 12),
                        Text(
                          'Your Carbon Credits',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Credits',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '12.5 tCO₂',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Estimated Value',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '€187.50',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: 0.75,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Next verification in 2 weeks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Payment Methods Section
            Text(
              'Payment Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            _buildPaymentMethodCard(
              'M-Pesa',
              'Mobile money transfer',
              Icons.phone_android,
              Colors.green,
              'Connect your M-Pesa account for instant payments',
              true,
            ),
            
            _buildPaymentMethodCard(
              'Bank Transfer',
              'Direct to your bank account',
              Icons.account_balance,
              Colors.blue,
              'Receive payments directly to your bank account',
              false,
            ),
            
            _buildPaymentMethodCard(
              'Digital Wallet',
              'Cryptocurrency payments',
              Icons.account_balance_wallet,
              Colors.orange,
              'Get paid in digital currency',
              false,
            ),
            
            SizedBox(height: 24),
            
            // Recent Transactions
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            _buildTransactionCard(
              'Payment Received',
              '€75.00',
              '5.0 tCO₂ credits verified',
              DateTime.now().subtract(Duration(days: 7)),
              true,
            ),
            
            _buildTransactionCard(
              'Verification Pending',
              '€45.00',
              '3.0 tCO₂ credits pending',
              DateTime.now().subtract(Duration(days: 3)),
              false,
            ),
            
            _buildTransactionCard(
              'Payment Received',
              '€67.50',
              '4.5 tCO₂ credits verified',
              DateTime.now().subtract(Duration(days: 14)),
              true,
            ),
            
            SizedBox(height: 24),
            
            // Cash Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showCashOutDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payments),
                    SizedBox(width: 8),
                    Text(
                      'Cash Out Credits',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentMethodCard(String title, String subtitle, IconData icon, 
      Color color, String description, bool isConnected) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isConnected 
            ? Icon(Icons.check_circle, color: Colors.green)
            : OutlinedButton(
                onPressed: () {
                  _showConnectPaymentDialog(title);
                },
                child: Text('Connect'),
              ),
        onTap: () {
          _showPaymentMethodDetails(title, description, isConnected);
        },
      ),
    );
  }
  
  Widget _buildTransactionCard(String title, String amount, String description,
      DateTime date, bool isCompleted) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted 
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          child: Icon(
            isCompleted ? Icons.check : Icons.schedule,
            color: isCompleted ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.green[700] : Colors.orange[700],
              ),
            ),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCashOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cash Out Carbon Credits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available: 12.5 tCO₂ (€187.50)'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Amount to cash out',
                hintText: '€0.00',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            Text(
              'Payment will be processed within 1-3 business days.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cash out request submitted!')),
              );
            },
            child: Text('Submit Request'),
          ),
        ],
      ),
    );
  }
  
  void _showConnectPaymentDialog(String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect $method'),
        content: Text('This feature will be available soon. '
            'You will be able to connect your $method account for seamless payments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showPaymentMethodDetails(String title, String description, bool isConnected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            SizedBox(height: 16),
            Text(
              isConnected ? 'Status: Connected' : 'Status: Not connected',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isConnected ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}