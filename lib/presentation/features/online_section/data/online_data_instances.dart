// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

import '../models/online_instance.dart';

const int kCategoryExplore = 0; // Explore home screen (no WebView)
const int kCategoryMusic = 1; // General music streaming
const int kCategoryMovies = 2; // Movies & TV series
const int kCategoryLoFi = 3; // Lo-Fi / ambient / chill radio
const int kCategoryRoyaltyFree = 4; // Royalty-free music for creators
const int kCategoryDocs = 5; // Documentaries
const int kCategoryCustom = 6; // User-added sites

// ─────────────────────────────────────────────────────────────────────────────
// BUILT-IN INSTANCES
//
// Replace or add URLs here — no other changes needed.
// Order determines which instance loads first when the category is opened.
// ─────────────────────────────────────────────────────────────────────────────

/// 🎵 Music Streaming
const List<OnlineInstance> kMusicInstances = [
  OnlineInstance(
    name: 'Hayasaka',
    url: 'https://hayasaka.8man.in/',
    description: 'Indie music streaming, ad-free',
  ),
  OnlineInstance(
    name: 'ArtistGrid',
    url: 'https://artistgrid.cx/',
    description: 'Discover artists & their music',
  ),
  OnlineInstance(
    name: 'MusicPlayer.io',
    url: 'https://musicplayer.io/',
    description: 'Web-based music player',
  ),
];

/// 🎬 Movies & TV Series
const List<OnlineInstance> kMovieInstances = [
  OnlineInstance(
    name: 'Cineby',
    url: 'https://www.cineby.gd/',
    description: 'Clean UI for movies & TV',
  ),
  OnlineInstance(
    name: 'Rivestream',
    url: 'https://rivestream.org/',
    description: 'Movies & web series',
  ),
  OnlineInstance(
    name: 'Fmovies+',
    url: 'https://www.fmovies.gd/home',
    description: 'Popular movie streaming',
  ),
  OnlineInstance(
    name: 'Cinevibe',
    url: 'https://cinevibe.asia/',
    description: 'Asian-friendly movie hub',
  ),
  OnlineInstance(
    name: 'Yflix',
    url: 'https://yflix.to/home',
    description: 'Movies & TV shows',
  ),
  OnlineInstance(
    name: 'CineMora',
    url: 'https://cinemora.ru/',
    description: 'International cinema',
  ),
  OnlineInstance(
    name: '67Movies',
    url: 'https://67movies.net/',
    description: 'HD movies catalog',
  ),
  OnlineInstance(
    name: '345Movie',
    url: 'https://345movie.nl/home',
    description: 'Free movie streaming',
  ),
  OnlineInstance(
    name: '1Moviez',
    url: 'https://1moviesz.to/home',
    description: 'Latest movies & series',
  ),
];

/// 🌙 Lo-Fi Radio & Ambient / Chill
const List<OnlineInstance> kLoFiInstances = [
  OnlineInstance(
    name: 'Lofi.limo',
    url: 'https://lofi.limo/',
    description: 'Lofi beats to study & relax',
  ),
  OnlineInstance(
    name: 'Loficafe',
    url: 'https://loficafe.net/',
    description: 'Chill cafe radio vibes',
  ),
  OnlineInstance(
    name: 'Flowtunes',
    url: 'https://www.flowtunes.app/',
    description: 'Focus music & flow state',
  ),
  OnlineInstance(
    name: 'FlowFi',
    url: 'https://www.flowfi.app/',
    description: 'Lofi for deep work',
  ),
  OnlineInstance(
    name: 'Lofizen',
    url: 'https://lofizen.co/',
    description: 'Zen lofi music app',
  ),
  OnlineInstance(
    name: 'Cityhop',
    url: 'https://www.cityhop.cafe/',
    description: 'Listen from city cafes worldwide',
  ),
  OnlineInstance(
    name: 'Moss Garden',
    url: 'https://moss.garden/',
    description: 'Ambient nature sounds',
  ),
  OnlineInstance(
    name: 'Ambicular',
    url: 'https://ambicular.com/',
    description: 'Ambient lofi vibes',
  ),
  OnlineInstance(
    name: 'Music for Programming',
    url: 'https://musicforprogramming.net/',
    description: 'Long mixes for deep focus',
  ),
  OnlineInstance(
    name: 'Code Radio',
    url: 'https://coderadio.freecodecamp.org/',
    description: 'freeCodeCamp chill radio',
  ),
  OnlineInstance(
    name: 'Coding Cat',
    url: 'https://hostrider.com/',
    description: 'Lofi beats for coders',
  ),
  OnlineInstance(
    name: 'Lofi & Games',
    url: 'https://www.lofiandgames.com/',
    description: 'Lofi + retro game ambience',
  ),
];

/// 🎸 Royalty-Free Music for Creators
const List<OnlineInstance> kRoyaltyFreeInstances = [
  OnlineInstance(
    name: 'NCS',
    url: 'https://ncs.io/',
    description: 'No Copyright Sounds — free forever',
  ),
  OnlineInstance(
    name: 'Bensound',
    url: 'https://www.bensound.com/',
    description: 'Royalty-free music for videos',
  ),
  OnlineInstance(
    name: 'Unminus',
    url: 'https://www.unminus.com/',
    description: 'Premium royalty-free, 100% free',
  ),
  OnlineInstance(
    name: 'TuneTank',
    url: 'https://tunetank.com/',
    description: 'Music for content creators',
  ),
];

/// 📽️ Documentaries
const List<OnlineInstance> kDocInstances = [
  OnlineInstance(
    name: 'Documentary+',
    url: 'https://docplus.com/home',
    description: 'Premium documentary streaming',
  ),
  OnlineInstance(
    name: 'Top Doc Films',
    url: 'https://topdocumentaryfilms.com/',
    description: 'Thousands of free documentaries',
  ),
  OnlineInstance(
    name: 'NASA+',
    url: 'https://plus.nasa.gov/',
    description: 'Space, Earth & science — free',
  ),
  OnlineInstance(
    name: 'ARTE',
    url: 'https://www.arte.tv/',
    description: 'European arts & culture docs',
  ),
  OnlineInstance(
    name: 'Thoughtmaybe',
    url: 'https://thoughtmaybe.com/',
    description: 'Critical & social documentaries',
  ),
  OnlineInstance(
    name: 'IHaveNoTV',
    url: 'https://ihavenotv.com/',
    description: 'Documentary archive, no login',
  ),
  OnlineInstance(
    name: 'Documentary.net',
    url: 'https://documentary.net/',
    description: 'Curated documentary library',
  ),
  OnlineInstance(
    name: 'Rocumentaries',
    url: 'https://rocumentaries.com/',
    description: 'Music & rock documentaries',
  ),
];
