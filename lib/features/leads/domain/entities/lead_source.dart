enum LeadSource {
  manual('Manual Entry'),
  excel('Excel Import'),
  csv('CSV Import'),
  portal('Web Portal'),
  metaCampaign('Ad Funnels');

  const LeadSource(this.displayName);

  final String displayName;
}

