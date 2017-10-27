/* tslint:disable:max-line-length */

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
  {
    accountType: 'FifaFut18Account',
    provider:    'fifa-fut-18',
    name:        'Fifa18 Fut',
    imageUrl:    'https://orig00.deviantart.net/6d00/f/2011/231/1/0/ea_games_logo_icon_by_mahesh69a-d473fzx.png',
  },
  {
    accountType: 'WEXAccount',
    provider:    'wex',
    name:        'WEX',
    imageUrl:    'https://steemit-production-imageproxy-upload.s3.amazonaws.com/DQmcSbfZqm2FENe5U6oqfTj8miGQw8dG6inVkqvBTnYyAnB',
  },
  {
    accountType: 'KrakenAccount',
    provider:    'kraken',
    name:        'Kraken',
    imageUrl:    'https://pbs.twimg.com/profile_images/460890160201093121/QRdWxA7C.png',
  },
];
