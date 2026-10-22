import '../../domain/entities/lead_source.dart';

/// Predefined suggestion lists for cities, states, and lead sources.
/// Users can pick from these suggestions or type any custom manual text.

const List<String> defaultCitySuggestions = [
  'Mumbai',
  'Delhi',
  'Bengaluru',
  'Hyderabad',
  'Ahmedabad',
  'Chennai',
  'Kolkata',
  'Surat',
  'Pune',
  'Jaipur',
  'Lucknow',
  'Kanpur',
  'Nagpur',
  'Indore',
  'Thane',
  'Bhopal',
  'Visakhapatnam',
  'Pimpri-Chinchwad',
  'Patna',
  'Vadodara',
  'Ghaziabad',
  'Ludhiana',
  'Agra',
  'Nashik',
  'Faridabad',
  'Meerut',
  'Rajkot',
  'Varanasi',
  'Srinagar',
  'Aurangabad',
  'Dhanbad',
  'Amritsar',
  'Navi Mumbai',
  'Allahabad',
  'Ranchi',
  'Howrah',
  'Coimbatore',
  'Jabalpur',
  'Gwalior',
  'Vijayawada',
  'Jodhpur',
  'Madurai',
  'Raipur',
  'Kota',
  'Guwahati',
  'Chandigarh',
  'Solapur',
  'Hubli-Dharwad',
  'Bareilly',
  'Moradabad',
  'Mysore',
  'Gurgaon',
  'Aligarh',
  'Jalandhar',
  'Tiruchirappalli',
  'Bhubaneswar',
  'Salem',
  'Warangal',
  'Mira-Bhayandar',
  'Thiruvananthapuram',
  'Bhiwandi',
  'Saharanpur',
  'Guntur',
  'Amravati',
  'Bikaner',
  'Noida',
  'Jamshedpur',
  'Bhilai',
  'Cuttack',
  'Firozabad',
  'Kochi',
  'Nellore',
  'Bhavnagar',
  'Dehradun',
  'Durgapur',
  'Asansol',
  'Rourkela',
  'Nanded',
  'Kolhapur',
  'Ajmer',
  'Akola',
  'Gulbarga',
  'Jamnagar',
  'Ujjain',
  'Loni',
  'Siliguri',
  'Jhansi',
  'Ulhasnagar',
  'Jammu',
  'Mangalore',
  'Erode',
  'Belgaum',
  'Ambattur',
  'Tirunelveli',
  'Malegaon',
  'Gaya',
  'Jalgaon',
  'Udaipur',
  'Maheshtala',
];

const List<String> defaultStateSuggestions = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Andaman and Nicobar Islands',
  'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Jammu and Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry',
  'California',
  'Texas',
  'New York',
  'Florida',
  'London',
  'Dubai',
  'Singapore',
];

const List<String> defaultSourceSuggestions = [
  'Manual Entry',
  'Web Portal',
  'Meta Campaign',
  'Excel Import',
  'CSV Import',
  'Google Ads',
  'Website Form',
  'Referral',
  'LinkedIn',
  'Cold Call',
  'Trade Show / Event',
  'Walk-in',
  'Partner',
  'Direct Mail',
  'Other',
];

/// Resolves a typed or selected source string into a corresponding [LeadSource].
/// If the text doesn't match an established enum name or displayName, falls back to [LeadSource.manual].
LeadSource resolveLeadSource(String? text) {
  if (text == null || text.trim().isEmpty) {
    return LeadSource.manual;
  }
  final lower = text.trim().toLowerCase();

  for (final source in LeadSource.values) {
    if (source.displayName.toLowerCase() == lower ||
        source.name.toLowerCase() == lower) {
      return source;
    }
  }

  if (lower.contains('meta') || lower.contains('facebook') || lower.contains('instagram')) {
    return LeadSource.metaCampaign;
  }
  if (lower.contains('portal') || lower.contains('website') || lower.contains('web')) {
    return LeadSource.portal;
  }
  if (lower.contains('excel') || lower.contains('xlsx') || lower.contains('xls')) {
    return LeadSource.excel;
  }
  if (lower.contains('csv')) {
    return LeadSource.csv;
  }

  return LeadSource.manual;
}
