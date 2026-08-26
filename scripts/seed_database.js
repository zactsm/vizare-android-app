const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Built-in .env file parser (zero dependencies)
const envPath = path.join(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  envContent.split('\n').forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) return;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx !== -1) {
      const key = trimmed.slice(0, eqIdx).trim();
      let val = trimmed.slice(eqIdx + 1).trim();
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      if (!process.env[key]) {
        process.env[key] = val;
      }
    }
  });
}

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('\x1b[31m[Error] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env\x1b[0m');
  console.log('To seed your live remote database directly from the CLI:');
  console.log('1. Copy .env.example to .env');
  console.log('2. Add your SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY');
  console.log('3. Run: node scripts/seed_database.js\n');
  console.log('Alternatively, you can copy the contents of supabase/seed.sql and paste them into your Supabase Dashboard SQL Editor.');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false }
});

const profiles = [
  {
    email: 'admin@vizare.com',
    password: 'AdminPassword123!',
    full_name: 'Vizare Administrator',
    phone: '+1 (555) 019-2831',
    role: 'admin',
    profile_pic: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    has_password: true,
    is_active: true
  },
  {
    email: 'sarah.jenkins@luxuryhomes.com',
    password: 'HomeownerPass123!',
    full_name: 'Sarah Jenkins',
    phone: '+1 (555) 342-8819',
    role: 'homeowner',
    profile_pic: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=400&q=80',
    has_password: true,
    is_active: true
  },
  {
    email: 'alexander.vance@vancerealty.com',
    password: 'HomeownerPass123!',
    full_name: 'Alexander Vance',
    phone: '+1 (555) 789-2244',
    role: 'homeowner',
    profile_pic: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    has_password: true,
    is_active: true
  },
  {
    email: 'elena.rostova@azureestates.com',
    password: 'HomeownerPass123!',
    full_name: 'Elena Rostova',
    phone: '+1 (555) 612-4490',
    role: 'homeowner',
    profile_pic: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
    has_password: true,
    is_active: true
  },
  {
    email: 'marcus.thorne@archilux.com',
    password: 'HomeownerPass123!',
    full_name: 'Marcus Thorne',
    phone: '+1 (555) 482-9901',
    role: 'homeowner',
    profile_pic: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    has_password: true,
    is_active: true
  },
  {
    email: 'isabella.cruz@pacificcoastal.com',
    password: 'HomeownerPass123!',
    full_name: 'Isabella Cruz',
    phone: '+1 (555) 831-2290',
    role: 'homeowner',
    profile_pic: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80',
    has_password: true,
    is_active: true
  },
  {
    email: 'david.chen@buyer.com',
    password: 'BuyerPass123!',
    full_name: 'David Chen',
    phone: '+1 (555) 901-3321',
    role: 'homebuyer',
    profile_pic: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    has_password: true,
    is_active: true
  },
  {
    email: 'olivia.taylor@buyer.com',
    password: 'BuyerPass123!',
    full_name: 'Olivia Taylor',
    phone: '+1 (555) 433-1188',
    role: 'homebuyer',
    profile_pic: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
    has_password: true,
    is_active: true
  },
  {
    email: 'james.wilson@buyer.com',
    password: 'BuyerPass123!',
    full_name: 'James Wilson',
    phone: '+1 (555) 720-4109',
    role: 'homebuyer',
    profile_pic: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80',
    has_password: true,
    is_active: true
  }
];

const listings = [
  {
    homeownerEmail: 'sarah.jenkins@luxuryhomes.com',
    name: 'The Glass Horizon Villa',
    location: 'Beverly Hills, CA 90210',
    price: '$4,850,000',
    description: 'An architectural masterpiece perched in the hills, featuring panoramic floor-to-ceiling glass walls, an infinity edge pool, open-concept living pavilion, and custom Italian designer finishes. Includes interactive 3D model view.',
    image_path: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/LittlestTokyo.glb',
    is_featured: true,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'alexander.vance@vancerealty.com',
    name: 'Neo Tokyo Skyline Penthouse',
    location: 'Shibuya, Tokyo, Japan',
    price: '$3,200,000',
    description: 'Spectacular multi-level urban penthouse overlooking the neon skyline. Features automated smart home climate systems, private sky deck, bespoke woodwork, and fully furnished spatial layout.',
    image_path: 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://sketchfab.com/3d-models/residential-family-house-b36b822986f44ca99e6cfec20386a955',
    is_featured: true,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'sarah.jenkins@luxuryhomes.com',
    name: 'Nordic Minimalist Residence',
    location: 'Aspen, CO 81611',
    price: '$2,450,000',
    description: 'Modern Scandinavian architectural retreat crafted with sustainable Douglas fir beams, polished concrete radiant floors, and floor-to-ceiling forest views. Includes bespoke timber exterior model.',
    image_path: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/AVIFTest/forest_house.glb',
    is_featured: true,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'elena.rostova@azureestates.com',
    name: 'Villa Serena Waterfront Estate',
    location: 'Miami Beach, FL 33139',
    price: '$6,900,000',
    description: 'Prime waterfront estate with private deep-water yacht dock, expansive outdoor entertaining terrace, resort-style heated pool, and lush tropical landscape architecture.',
    image_path: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://sketchfab.com/3d-models/low-poly-house-1-72b37584f1a74e66914d4c57ea7f70d8',
    is_featured: true,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'alexander.vance@vancerealty.com',
    name: 'The Modernist Cantilever House',
    location: 'Austin, TX 78746',
    price: '$1,875,000',
    description: 'Dramatic steel and cedar cantilever residence nestled into the hillside. Boasts energy-positive solar arrays, smart automated illumination, and custom industrial fixture fittings.',
    image_path: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://sketchfab.com/3d-models/low-poly-house-5-d39346d08e494adfb4d1c70db350f2ce',
    is_featured: false,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600573472591-ee6b68d14c68?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'sarah.jenkins@luxuryhomes.com',
    name: 'The Obsidian Contemporary Penthouse',
    location: 'Tribeca, New York, NY 10013',
    price: '$5,400,000',
    description: 'High-floor Tribeca loft penthouse with 14-foot ceilings, direct key-elevator access, private wrap-around terrace, custom marble fireplace lounge, and breathtaking river vistas.',
    image_path: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://sketchfab.com/3d-models/low-poly-house-4-7b9d7d2a530648fe8ab096c9fba23be9',
    is_featured: false,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600585152220-90363fe7e115?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'elena.rostova@azureestates.com',
    name: 'Heritage Craftsman Villa & Studio',
    location: 'Pasadena, CA 91105',
    price: '$1,650,000',
    description: 'Elegantly restored 1920s Craftsman residence featuring handcrafted mahogany joinery, original river rock fireplace, stone masonry accents, and detached guest carriage house.',
    image_path: 'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://raw.githubusercontent.com/BabylonJS/Assets/master/meshes/villagePack/cottage/cottage.glb',
    is_featured: false,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1570129477492-45c003edd2be?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'alexander.vance@vancerealty.com',
    name: 'Celestial Horizon Gallery Loft',
    location: 'Seattle, WA 98101',
    price: '$1,290,000',
    description: 'Top-floor modern gallery loft in downtown Seattle featuring exposed industrial trusses, polished epoxy floors, museum lighting grid, and avant-garde architectural sculptures.',
    image_path: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://sketchfab.com/3d-models/low-poly-house-3-d7d42b52319d44cf89d6d6404970cd46',
    is_featured: false,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600607688969-a5bfcd646154?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'sarah.jenkins@luxuryhomes.com',
    name: 'Sunset Ridge Modern Estate',
    location: 'Scottsdale, AZ 85255',
    price: '$2,950,000',
    description: 'Newly constructed desert modern estate featuring rammed-earth accent walls, zero-edge reflection pool, indoor-outdoor glass pocket doors, and iridescent ambient illumination.',
    image_path: 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://raw.githubusercontent.com/BabylonJS/Assets/master/meshes/house_scene.glb',
    is_featured: false,
    status: 'pending',
    images: [
      'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600585154363-67eb9e2e2099?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'elena.rostova@azureestates.com',
    name: 'Pinecrest Alpine Sanctuary',
    location: 'Lake Tahoe, NV 89449',
    price: '$3,750,000',
    description: 'Custom timber and stone alpine retreat with private ski trail access, heated driveway, wellness sauna pavilion, and state-of-the-art acoustic listening lounge.',
    image_path: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://raw.githubusercontent.com/BabylonJS/Assets/master/meshes/villagePack/inn/inn.glb',
    is_featured: false,
    status: 'draft',
    images: [
      'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1518780664697-55e3ad937233?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'alexander.vance@vancerealty.com',
    name: 'Cyberpunk Artefact Penthouse Gallery',
    location: 'San Francisco, CA 94105',
    price: '$4,100,000',
    description: 'Exclusive SoMa tech penthouse with high-security biometric entry, private roof garden, and panoramic city views across the futuristic downtown skyline.',
    image_path: 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/VirtualCity/glTF-Binary/VirtualCity.glb',
    is_featured: false,
    status: 'sold',
    images: [
      'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'sarah.jenkins@luxuryhomes.com',
    name: 'Rolling Hills Farmstead & Manor',
    location: 'Nashville, TN 37215',
    price: '$1,450,000',
    description: 'Pastoral country estate with 10 rolling acres, equestrian stables, heritage millhouse lodge architecture, and natural creek frontage.',
    image_path: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://raw.githubusercontent.com/BabylonJS/Assets/master/meshes/villagePack/sawMill/sawMill.glb',
    is_featured: false,
    status: 'rejected',
    images: [
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1570129477492-45c003edd2be?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'marcus.thorne@archilux.com',
    name: 'Azure Coastline Mediterranean Villa',
    location: 'Malibu, CA 90265',
    price: '$8,250,000',
    description: 'Gated oceanfront compound with dual Mediterranean guest villas, private bluff staircase to beach, infinity jacuzzi, and expansive terracotta loggias overlooking the Pacific.',
    image_path: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://sketchfab.com/3d-models/low-poly-house-2-470dd32acf1847c29acaf0fc898e414b',
    is_featured: true,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600566752355-35792bedcfea?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'isabella.cruz@pacificcoastal.com',
    name: 'Emerald Valley Alpine Resort Estate',
    location: 'Vail, CO 81657',
    price: '$5,600,000',
    description: 'Expansive alpine valley estate surrounded by pristine aspen groves. Includes main chalet, secondary guest lodge, private trout stream, and heated outdoor stone terrace.',
    image_path: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://sketchfab.com/3d-models/low-poly-house-3-d2722c2e056a48ca8c922298b7a9e88b',
    is_featured: false,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1598228723793-52759bba239c?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1576941089067-2de3c901e126?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'marcus.thorne@archilux.com',
    name: 'Old Town Heritage Architectural Manor',
    location: 'Savannah, GA 31401',
    price: '$2,150,000',
    description: 'Historic antebellum brick manor with wrought-iron balconies, private courtyard gardens, restored heart-pine flooring, and 12-foot double-hung sash windows.',
    image_path: 'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://sketchfab.com/3d-models/low-poly-home-2-f5e7be986a524c3c976c726a9f2b2061',
    is_featured: false,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'isabella.cruz@pacificcoastal.com',
    name: 'The Victorian Gothic Historic Mansion',
    location: 'Garden District, New Orleans, LA 70130',
    price: '$3,890,000',
    description: 'Stately Garden District mansion featuring gothic architecture, soaring turrets, original gas-flame lanterns, ornate plaster molding, and secluded magnolia grounds.',
    image_path: 'https://images.unsplash.com/photo-1518780664697-55e3ad937233?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://raw.githubusercontent.com/BabylonJS/Assets/master/meshes/haunted_house.glb',
    is_featured: false,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1518780664697-55e3ad937233?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1570129477492-45c003edd2be?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600585154363-67eb9e2e2099?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'marcus.thorne@archilux.com',
    name: 'SoHo Industrial Modern Loft',
    location: 'SoHo, New York, NY 10012',
    price: '$3,450,000',
    description: 'Cast-iron building corner loft with barrel-vaulted brick ceilings, oversized Corinthian columns, polished concrete floors, and custom minimalist steel architectural framing.',
    image_path: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://sketchfab.com/3d-models/low-poly-stylized-home-ca64053dca474ff2825eedaaf8eb98d1',
    is_featured: false,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'isabella.cruz@pacificcoastal.com',
    name: 'Skyline Terrace Duplex Penthouse',
    location: 'Gold Coast, Chicago, IL 60611',
    price: '$2,780,000',
    description: 'Luxury two-story duplex penthouse overlooking Lake Michigan. Features custom floating glass staircase, 800 sq ft private terrace with outdoor fireplace, and smart Lutron automation.',
    image_path: 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://sketchfab.com/3d-models/low-poly-medieval-house-1-81b8d567c94945059918e0bf303c8310',
    is_featured: false,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600585152220-90363fe7e115?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600607688969-a5bfcd646154?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'sarah.jenkins@luxuryhomes.com',
    name: 'Grand Arch Modernist Passageway Villa',
    location: 'Palm Springs, CA 92264',
    price: '$3,120,000',
    description: 'Mid-century modern desert oasis with iconic structural archway, sunken fire pit lounge, saltwater lap pool, and panoramic views of the San Jacinto mountain range.',
    image_path: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://raw.githubusercontent.com/BabylonJS/Assets/master/meshes/Buildings/road gap.glb',
    is_featured: false,
    status: 'pending',
    images: [
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&q=80'
    ]
  },
  {
    homeownerEmail: 'elena.rostova@azureestates.com',
    name: 'Highland Geometric Eco-Residence',
    location: 'Portland, OR 97201',
    price: '$1,980,000',
    description: 'LEED Platinum certified hillside residence featuring green roof garden, geo-thermal heating, triple-pane floor-to-ceiling glass, and sustainable western red cedar siding.',
    image_path: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
    model_path: 'https://sketchfab.com/3d-models/low-poly-wooden-cabine-5cb73d080fcb4968b50c6d4b040a04e6',
    is_featured: false,
    status: 'approved',
    images: [
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1598228723793-52759bba239c?auto=format&fit=crop&w=1200&q=80'
    ]
  }
];

async function seedRemoteDatabase() {
  console.log('🚀 Connecting to Supabase at:', SUPABASE_URL);

  // 1. Provision Auth Users and Seed Public Profiles
  console.log('\n1. Provisioning Auth Users & Public Profiles...');
  for (const p of profiles) {
    let authUserId = null;
    try {
      const { data: created, error: createErr } = await supabase.auth.admin.createUser({
        email: p.email,
        password: p.password,
        email_confirm: true,
        user_metadata: { full_name: p.full_name, role: p.role, has_password: true }
      });
      if (created && created.user) {
        authUserId = created.user.id;
      } else if (createErr && createErr.message?.toLowerCase().includes('already')) {
        // User already exists in auth.users, find their UUID
        const { data: listData } = await supabase.auth.admin.listUsers();
        const existing = listData?.users?.find(u => u.email?.toLowerCase() === p.email.toLowerCase());
        if (existing) authUserId = existing.id;
      }
    } catch (authErr) {
      console.warn(`  Notice during auth creation for ${p.email}:`, authErr.message);
    }

    const profileData = {
      email: p.email,
      full_name: p.full_name,
      phone: p.phone,
      role: p.role,
      profile_pic: p.profile_pic,
      has_password: p.has_password,
      is_active: p.is_active,
      ...(authUserId ? { auth_user_id: authUserId } : {})
    };

    const { error: profError } = await supabase
      .from('profiles')
      .upsert(profileData, { onConflict: 'email' });

    if (profError) {
      // If auth_user_id foreign key failed, try without auth_user_id
      delete profileData.auth_user_id;
      const { error: retryError } = await supabase.from('profiles').upsert(profileData, { onConflict: 'email' });
      if (retryError) console.error('  ⚠️ Error upserting profile', p.email, retryError.message);
      else console.log('  ✅ Profile ready (standalone):', p.email);
    } else {
      console.log('  ✅ Profile ready:', p.email);
    }
  }

  // Fetch profile ID map
  const { data: profileList, error: profErr } = await supabase.from('profiles').select('id,email');
  if (profErr || !profileList) {
    console.error('Failed to fetch profile IDs:', profErr);
    process.exit(1);
  }
  const profileMap = new Map(profileList.map(p => [p.email, p.id]));

  // 2. Seed Notification Preferences
  console.log('\n2. Seeding Notification Preferences...');
  for (const [email, pid] of profileMap.entries()) {
    await supabase.from('notification_preferences').upsert({
      profile_id: pid,
      push_notifications: true,
      email_notifications: true,
      in_app_notifications: true
    }, { onConflict: 'profile_id' });
  }
  console.log('  ✅ Notification preferences configured for all profiles');

  // 3. Seed Properties
  console.log('\n3. Upserting 20 Property Listings...');
  const propertyIdMap = new Map();

  for (const l of listings) {
    const homeownerId = profileMap.get(l.homeownerEmail);
    if (!homeownerId) {
      console.warn('  ⚠️ Homeowner ID not found for', l.homeownerEmail);
      continue;
    }

    const propPayload = {
      homeowner_id: homeownerId,
      name: l.name,
      location: l.location,
      price: l.price,
      description: l.description,
      image_path: l.image_path,
      model_path: l.model_path,
      is_featured: l.is_featured,
      status: l.status
    };

    // Check if property exists by name
    const { data: existingProp } = await supabase
      .from('properties')
      .select('id')
      .eq('name', l.name)
      .maybeSingle();

    let propId = existingProp?.id;

    if (propId) {
      const { error: updErr } = await supabase
        .from('properties')
        .update(propPayload)
        .eq('id', propId);
      if (updErr) {
        console.error('  ⚠️ Error updating property:', l.name, updErr.message);
        continue;
      }
    } else {
      const { data: inserted, error: insErr } = await supabase
        .from('properties')
        .insert(propPayload)
        .select('id')
        .single();
      if (insErr) {
        console.error('  ⚠️ Error inserting property:', l.name, insErr.message);
        continue;
      }
      propId = inserted.id;
    }

    propertyIdMap.set(l.name, propId);
    console.log('  ✅ Property seeded:', l.name, `(ID: ${propId})`);

    // 4. Seed Property Images
    const imagesToInsert = l.images.map((url, sort_order) => ({
      property_id: propId,
      image_url: url,
      sort_order
    }));

    await supabase.from('property_images').delete().eq('property_id', propId);
    const { error: imgErr } = await supabase.from('property_images').insert(imagesToInsert);
    if (imgErr) console.error('    ⚠️ Error seeding images:', imgErr.message);
    else console.log(`    📸 Seeded ${imagesToInsert.length} gallery images`);
  }

  // 5. Seed Favorites & Inquiries
  console.log('\n4. Seeding Favorites & Inquiries...');
  const chenId = profileMap.get('david.chen@buyer.com');
  const taylorId = profileMap.get('olivia.taylor@buyer.com');
  const wilsonId = profileMap.get('james.wilson@buyer.com');
  const sarahId = profileMap.get('sarah.jenkins@luxuryhomes.com');
  const vanceId = profileMap.get('alexander.vance@vancerealty.com');
  const elenaId = profileMap.get('elena.rostova@azureestates.com');

  const prop1Id = propertyIdMap.get('The Glass Horizon Villa');
  const prop2Id = propertyIdMap.get('Neo Tokyo Skyline Penthouse');
  const prop4Id = propertyIdMap.get('Villa Serena Waterfront Estate');

  if (chenId && prop1Id) {
    await supabase.from('favorites').upsert({ profile_id: chenId, property_id: prop1Id }, { onConflict: 'profile_id,property_id' });
    if (prop2Id) await supabase.from('favorites').upsert({ profile_id: chenId, property_id: prop2Id }, { onConflict: 'profile_id,property_id' });
  }
  if (taylorId && prop4Id) {
    await supabase.from('favorites').upsert({ profile_id: taylorId, property_id: prop4Id }, { onConflict: 'profile_id,property_id' });
  }

  if (sarahId && prop1Id) {
    await supabase.from('inquiries').insert({
      homeowner_id: sarahId,
      property_id: prop1Id,
      property_name: 'The Glass Horizon Villa',
      property_image: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
      buyer_email: 'david.chen@buyer.com',
      message: 'Hello Sarah, I am captivated by the 3D model and architecture of The Glass Horizon Villa. Is it possible to schedule a private tour this coming Saturday?',
      is_read: false
    });
  }

  console.log('  ✅ Seeded Favorites and Inquiries');
  console.log('\n🎉 Live Supabase Database Seeding Completed Successfully!\n');
}

seedRemoteDatabase().catch(console.error);
