import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 6,
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Privacy Policy",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "This Privacy Policy applies to the sabbafarm.com",
              ),
              const SizedBox(height: 8),
              const Text(
                "Sabbafarm.com recognises the importance of maintaining your privacy. "
                "We value your privacy and appreciate your trust in us. This Policy describes how we treat user information we collect on "
                "https://www.sabbafarm.com and other offline sources. This Privacy Policy applies to current and former visitors to our website "
                "and to our online customers. By visiting and/or using our website, you agree to this Privacy Policy.",
              ),
              const SizedBox(height: 8),
              const Text(
                "Sabbafarm.com is a property of SRI SANTHOSH SOWJANYA AGENCIES, "
                "an Indian PARTNERSHIP FIRM registered under the Andhra Pradesh Goods and Services Tax Act, 2017, "
                "1-5/3, Vedurupaka Road, Pasalapudi, ANDHRA PRADESH 533261.",
              ),

              _sectionTitle("Information we collect"),
              _bulletList([
                "Contact information: name, email, mobile number, phone number, street, city, state, pincode, country and IP address.",
                "Payment and billing information: billing name, billing address and payment method. We NEVER collect your credit card number or expiry date. Payment is handled by our partner CC Avenue.",
                "Information you post: content posted on public spaces on our website or third-party social media pages.",
                "Demographic information: details like products you buy, information provided via surveys.",
                "Other information: browser type, time spent, pages visited, referring sites, mobile device type, OS version.",
              ]),

              _sectionTitle("How we collect information"),
              _bulletList([
                "Directly from you: when you register, buy, post comments, or ask questions.",
                "Passively: via tools like Google Analytics, Google Webmaster, cookies, and web beacons.",
                "From third-parties: integrated features from social media may provide your name and email address.",
              ]),

              _sectionTitle("Use of your personal information"),
              _bulletList([
                "To contact you for confirmation or promotions.",
                "To respond to your queries or confirm registrations.",
                "To customize your experience and improve services.",
                "To analyze site trends and user interests.",
                "For security and fraud prevention.",
                "For marketing: to send promotions or newsletters.",
                "To send transactional communication (e.g., order updates).",
                "As otherwise permitted by law.",
              ]),

              _sectionTitle("Third-party sites"),
              const Text(
                "If you click on a third-party link, you may be taken to websites we do not control. This Privacy Policy does not apply to their practices. "
                "Please review their privacy policies carefully. Sabbafarm.com is not responsible for third-party site practices.",
              ),

              _sectionTitle("Grievance Officer"),
              const SizedBox(height: 4),
              const Text("Mr. SABBARAPU SANTOSH KUMAR"),
              const Text("SRI SANTHOSH SOWJANYA AGENCIES"),
              const Text("Phone: +91 9171749999"),
              const Text("Email: customercare@sabbafarm.com"),

              const SizedBox(height: 16),
              const Text(
                "Last Updated: April 30, 2025",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.green[600],
        ),
      ),
    );
  }

  Widget _bulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ",
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        )),
                    Expanded(
                      child: Text(
                        e,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}