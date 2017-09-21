export interface AccountCategory {
  accountType: string;
  provider:    string;
  name:        string;
  imageUrl:    string;
}

export const ACCOUNT_CATEGORIES: AccountCategory[] = [
  {
    accountType: 'OAuthAccount',
    provider:    'twitter',
    name:        'Twitter',
    imageUrl:    'https://www.seeklogo.net/wp-content/uploads/2016/11/twitter-icon-circle-blue-logo-preview.png',
  },
];
