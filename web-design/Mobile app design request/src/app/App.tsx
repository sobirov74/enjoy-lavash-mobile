import { useState } from 'react';
import { Home, ShoppingCart, User, Plus, Minus, X, QrCode, ChevronRight, Clock, MapPin, Phone, Mail, CreditCard } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import { motion, AnimatePresence } from 'motion/react';
import logo from "../imports/image-1.png";

interface Product {
  id: number;
  name: string;
  price: number;
  image: string;
  category: string;
}

interface CartItem extends Product {
  quantity: number;
}

interface Order {
  id: string;
  date: string;
  items: CartItem[];
  total: number;
  status: 'completed' | 'processing' | 'cancelled';
}

const products: Product[] = [
  { id: 1, name: 'Лаваш куриный с сыром', price: 36000, image: '🌯', category: 'Лавашлар' },
  { id: 2, name: 'Лаваш куриный', price: 32000, image: '🌯', category: 'Лавашлар' },
  { id: 3, name: 'Лаваш сети', price: 38000, image: '🥙', category: 'Лавашлар' },
  { id: 4, name: 'Лаваш Биг', price: 40000, image: '🌯', category: 'Лавашлар' },
  { id: 5, name: 'Картошка фри', price: 12000, image: '🍟', category: 'Гарнир' },
  { id: 6, name: 'Pepsi', price: 8000, image: '🥤', category: 'Напитки' },
  { id: 7, name: 'Шашлык', price: 45000, image: '🍢', category: 'Хот-дог' },
  { id: 8, name: 'Бургер классик', price: 35000, image: '🍔', category: 'Бургеры' },
];

const categories = ['Лавашлар', 'Пицца', 'Бургеры', 'Дамлама', 'Хот-дог', 'Гарнир'];

const mockOrders: Order[] = [
  {
    id: 'ORD-2024-001',
    date: '2026-04-10',
    items: [
      { id: 1, name: 'Лаваш куриный с сыром', price: 36000, image: '🌯', category: 'Лавашлар', quantity: 2 },
      { id: 6, name: 'Pepsi', price: 8000, image: '🥤', category: 'Напитки', quantity: 1 },
    ],
    total: 80000,
    status: 'completed',
  },
  {
    id: 'ORD-2024-002',
    date: '2026-04-08',
    items: [
      { id: 8, name: 'Бургер классик', price: 35000, image: '🍔', category: 'Бургеры', quantity: 1 },
      { id: 5, name: 'Картошка фри', price: 12000, image: '🍟', category: 'Гарнир', quantity: 1 },
    ],
    total: 47000,
    status: 'completed',
  },
];

export default function App() {
  const [activeTab, setActiveTab] = useState<'home' | 'cart' | 'profile'>('home');
  const [selectedCategory, setSelectedCategory] = useState('Лавашлар');
  const [cart, setCart] = useState<CartItem[]>([]);
  const [loyaltyPoints, setLoyaltyPoints] = useState(1250);
  const [showMenuQR, setShowMenuQR] = useState(false);
  const [orders] = useState<Order[]>(mockOrders);

  const filteredProducts = products.filter(p => p.category === selectedCategory);

  const addToCart = (product: Product) => {
    setCart(prev => {
      const existing = prev.find(item => item.id === product.id);
      if (existing) {
        return prev.map(item =>
          item.id === product.id ? { ...item, quantity: item.quantity + 1 } : item
        );
      }
      return [...prev, { ...product, quantity: 1 }];
    });
  };

  const updateQuantity = (id: number, delta: number) => {
    setCart(prev => {
      const updated = prev.map(item =>
        item.id === id ? { ...item, quantity: Math.max(0, item.quantity + delta) } : item
      ).filter(item => item.quantity > 0);
      return updated;
    });
  };

  const removeFromCart = (id: number) => {
    setCart(prev => prev.filter(item => item.id !== id));
  };

  const totalAmount = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const totalItems = cart.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <div className="h-screen flex flex-col bg-neutral-50 max-w-md mx-auto">
      {/* Header */}
      <header className="bg-gradient-to-r from-red-500 to-red-600 px-5 py-4 shadow-lg">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <img src={logo} alt="Enjoy" className="w-12 h-12 object-contain bg-white rounded-xl p-1.5" />
            <div>
              <h1 className="text-white text-xl tracking-tight">EnjoyLavash</h1>
              <p className="text-red-100 text-xs">Вкусно и быстро</p>
            </div>
          </div>
          {activeTab === 'home' && (
            <button
              onClick={() => setShowMenuQR(true)}
              className="w-10 h-10 bg-white/20 hover:bg-white/30 rounded-xl flex items-center justify-center text-white transition-colors"
            >
              <QrCode size={20} />
            </button>
          )}
        </div>
      </header>

      {/* Content */}
      <main className="flex-1 overflow-y-auto pb-20">
        <AnimatePresence mode="wait">
          {activeTab === 'home' && (
            <motion.div
              key="home"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.2 }}
            >
              {/* Promotional Banner */}
              <div className="px-4 pt-4 pb-2">
                <div className="bg-gradient-to-r from-amber-400 to-orange-500 rounded-2xl p-5 shadow-lg relative overflow-hidden">
                  <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -mr-16 -mt-16"></div>
                  <div className="absolute bottom-0 left-0 w-24 h-24 bg-white/10 rounded-full -ml-12 -mb-12"></div>
                  <div className="relative z-10">
                    <h3 className="text-white text-lg mb-1">Специальное предложение!</h3>
                    <p className="text-white/90 text-sm mb-3">Скидка 20% на все лаваши до конца недели</p>
                    <div className="inline-block bg-white/20 backdrop-blur-sm px-3 py-1.5 rounded-full">
                      <span className="text-white text-xs font-medium">🔥 Успейте заказать!</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Categories */}
              <div className="px-4 py-4 overflow-x-auto">
                <div className="flex gap-2">
                  {categories.map(cat => (
                    <button
                      key={cat}
                      onClick={() => setSelectedCategory(cat)}
                      className={`px-5 py-2.5 rounded-full whitespace-nowrap transition-all shadow-sm ${
                        selectedCategory === cat
                          ? 'bg-red-500 text-white shadow-red-200'
                          : 'bg-white text-neutral-700 hover:bg-neutral-50'
                      }`}
                    >
                      {cat}
                    </button>
                  ))}
                </div>
              </div>

              {/* Products */}
              <div className="px-4 pb-4">
                <h2 className="text-xl mb-4">{selectedCategory}</h2>
                {filteredProducts.length > 0 ? (
                  <div className="grid grid-cols-2 gap-3">
                    {filteredProducts.map(product => (
                      <motion.div
                        key={product.id}
                        layout
                        initial={{ opacity: 0, scale: 0.9 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="bg-white rounded-2xl overflow-hidden shadow-md hover:shadow-lg transition-shadow"
                      >
                        <div className="aspect-square bg-gradient-to-br from-orange-50 to-red-50 flex items-center justify-center text-6xl relative">
                          {product.image}
                        </div>
                        <div className="p-3">
                          <h3 className="text-sm mb-2 h-10 line-clamp-2">{product.name}</h3>
                          <div className="flex items-center justify-between">
                            <span className="font-semibold text-red-600">{product.price.toLocaleString()} сўм</span>
                            <button
                              onClick={() => addToCart(product)}
                              className="w-9 h-9 bg-red-500 text-white rounded-xl flex items-center justify-center hover:bg-red-600 transition-colors shadow-md"
                            >
                              <Plus size={18} />
                            </button>
                          </div>
                        </div>
                      </motion.div>
                    ))}
                  </div>
                ) : (
                  <div className="flex flex-col items-center justify-center py-16">
                    <div className="w-24 h-24 bg-neutral-100 rounded-full flex items-center justify-center text-5xl mb-4">
                      🍽️
                    </div>
                    <h3 className="text-lg mb-2">Товары не найдены</h3>
                    <p className="text-neutral-500 text-sm text-center px-8">
                      В этой категории пока нет товаров
                    </p>
                  </div>
                )}
              </div>
            </motion.div>
          )}

          {activeTab === 'cart' && (
            <motion.div
              key="cart"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.2 }}
              className="p-4"
            >
              <h2 className="text-2xl mb-6">Корзина</h2>

              {cart.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-20 px-8">
                  <div className="w-40 h-40 bg-gradient-to-br from-red-50 to-orange-50 rounded-full flex items-center justify-center text-7xl mb-6 shadow-inner">
                    🛒
                  </div>
                  <h3 className="text-2xl mb-3">Корзина пуста</h3>
                  <p className="text-neutral-500 text-center mb-8 max-w-xs">
                    Добавьте вкусные блюда из нашего меню в корзину
                  </p>
                  <button
                    onClick={() => setActiveTab('home')}
                    className="px-8 py-4 bg-gradient-to-r from-red-500 to-red-600 text-white rounded-2xl hover:shadow-lg transition-all"
                  >
                    Перейти к меню
                  </button>
                </div>
              ) : (
                <>
                  <div className="space-y-3 mb-6">
                    {cart.map(item => (
                      <motion.div
                        key={item.id}
                        layout
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: 20 }}
                        className="bg-white rounded-2xl p-4 shadow-md"
                      >
                        <div className="flex gap-4">
                          <div className="w-24 h-24 bg-gradient-to-br from-orange-50 to-red-50 rounded-2xl flex items-center justify-center text-5xl flex-shrink-0">
                            {item.image}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between mb-2">
                              <h3 className="text-sm pr-2 leading-snug">{item.name}</h3>
                              <button
                                onClick={() => removeFromCart(item.id)}
                                className="text-neutral-400 hover:text-red-500 transition-colors"
                              >
                                <X size={20} />
                              </button>
                            </div>
                            <p className="text-red-600 font-semibold mb-3">{item.price.toLocaleString()} сўм</p>
                            <div className="flex items-center gap-3">
                              <button
                                onClick={() => updateQuantity(item.id, -1)}
                                className="w-9 h-9 bg-neutral-100 rounded-xl flex items-center justify-center hover:bg-neutral-200 transition-colors"
                              >
                                <Minus size={16} />
                              </button>
                              <span className="w-8 text-center font-semibold">{item.quantity}</span>
                              <button
                                onClick={() => updateQuantity(item.id, 1)}
                                className="w-9 h-9 bg-red-500 text-white rounded-xl flex items-center justify-center hover:bg-red-600 transition-colors"
                              >
                                <Plus size={16} />
                              </button>
                            </div>
                          </div>
                        </div>
                      </motion.div>
                    ))}
                  </div>

                  <div className="bg-white rounded-2xl p-6 shadow-lg border border-neutral-100">
                    <div className="flex items-center justify-between mb-6">
                      <span className="text-neutral-600">Итого:</span>
                      <span className="text-3xl font-bold text-red-600">{totalAmount.toLocaleString()} сўм</span>
                    </div>
                    <button className="w-full py-4 bg-gradient-to-r from-red-500 to-red-600 text-white rounded-2xl hover:shadow-lg transition-all font-medium">
                      Оформить заказ
                    </button>
                  </div>
                </>
              )}
            </motion.div>
          )}

          {activeTab === 'profile' && (
            <motion.div
              key="profile"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.2 }}
              className="p-4"
            >
              <h2 className="text-2xl mb-6">Профиль</h2>

              {/* User Info */}
              <div className="bg-white rounded-2xl p-6 mb-4 shadow-md">
                <div className="flex items-center gap-4">
                  <div className="w-20 h-20 bg-gradient-to-br from-amber-400 to-red-500 rounded-2xl flex items-center justify-center text-3xl shadow-lg">
                    👤
                  </div>
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold mb-1">Гость</h3>
                    <p className="text-neutral-500 text-sm flex items-center gap-1">
                      <Phone size={14} /> +998 90 123 45 67
                    </p>
                  </div>
                  <button className="text-neutral-400 hover:text-red-500">
                    <ChevronRight size={20} />
                  </button>
                </div>
              </div>

              {/* Loyalty Card */}
              <div className="bg-gradient-to-br from-red-500 via-red-600 to-orange-500 rounded-2xl p-6 mb-4 text-white shadow-xl relative overflow-hidden">
                <div className="absolute top-0 right-0 w-40 h-40 bg-white/10 rounded-full -mr-20 -mt-20"></div>
                <div className="absolute bottom-0 left-0 w-32 h-32 bg-white/5 rounded-full -ml-16 -mb-16"></div>
                <div className="relative z-10">
                  <h3 className="text-lg mb-1">Карта лояльности</h3>
                  <p className="text-sm opacity-90 mb-6">Накопленные баллы</p>
                  <div className="text-5xl font-bold mb-6">{loyaltyPoints.toLocaleString()}</div>

                  <div className="bg-white rounded-2xl p-5 flex justify-center">
                    <QRCodeSVG
                      value={`ENJOY-LAVASH-USER-12345-POINTS-${loyaltyPoints}`}
                      size={200}
                      level="H"
                      includeMargin={true}
                    />
                  </div>

                  <p className="text-center text-sm mt-5 opacity-90">
                    Покажите этот QR-код при оплате для начисления баллов
                  </p>
                </div>
              </div>

              {/* Private Data */}
              <div className="bg-white rounded-2xl p-6 mb-4 shadow-md">
                <h3 className="text-lg mb-4 font-semibold">Личные данные</h3>
                <div className="space-y-4">
                  <div className="flex items-center gap-3 text-sm">
                    <div className="w-10 h-10 bg-red-50 rounded-xl flex items-center justify-center text-red-500">
                      <Mail size={18} />
                    </div>
                    <div>
                      <p className="text-neutral-500 text-xs">Email</p>
                      <p className="font-medium">guest@enjolavash.uz</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 text-sm">
                    <div className="w-10 h-10 bg-red-50 rounded-xl flex items-center justify-center text-red-500">
                      <MapPin size={18} />
                    </div>
                    <div>
                      <p className="text-neutral-500 text-xs">Адрес</p>
                      <p className="font-medium">г. Ташкент, ул. Навои 25</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 text-sm">
                    <div className="w-10 h-10 bg-red-50 rounded-xl flex items-center justify-center text-red-500">
                      <CreditCard size={18} />
                    </div>
                    <div>
                      <p className="text-neutral-500 text-xs">ID клиента</p>
                      <p className="font-medium">EL-12345</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Order History */}
              <div className="bg-white rounded-2xl p-6 shadow-md">
                <h3 className="text-lg mb-4 font-semibold">История заказов</h3>
                {orders.length > 0 ? (
                  <div className="space-y-3">
                    {orders.map(order => (
                      <div key={order.id} className="border border-neutral-100 rounded-xl p-4 hover:border-red-200 transition-colors">
                        <div className="flex items-start justify-between mb-3">
                          <div>
                            <p className="font-medium text-sm">{order.id}</p>
                            <p className="text-xs text-neutral-500 flex items-center gap-1 mt-1">
                              <Clock size={12} />
                              {new Date(order.date).toLocaleDateString('ru-RU', { day: 'numeric', month: 'long', year: 'numeric' })}
                            </p>
                          </div>
                          <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                            order.status === 'completed' ? 'bg-green-100 text-green-700' :
                            order.status === 'processing' ? 'bg-blue-100 text-blue-700' :
                            'bg-neutral-100 text-neutral-700'
                          }`}>
                            {order.status === 'completed' ? 'Выполнен' :
                             order.status === 'processing' ? 'В обработке' : 'Отменён'}
                          </span>
                        </div>
                        <div className="space-y-1 mb-3">
                          {order.items.map((item, idx) => (
                            <p key={idx} className="text-sm text-neutral-600">
                              {item.image} {item.name} × {item.quantity}
                            </p>
                          ))}
                        </div>
                        <div className="flex items-center justify-between pt-3 border-t border-neutral-100">
                          <span className="text-sm text-neutral-600">Итого:</span>
                          <span className="font-semibold text-red-600">{order.total.toLocaleString()} сўм</span>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="flex flex-col items-center justify-center py-12">
                    <div className="w-24 h-24 bg-neutral-100 rounded-full flex items-center justify-center text-5xl mb-4">
                      📦
                    </div>
                    <h4 className="text-lg mb-2">Нет заказов</h4>
                    <p className="text-neutral-500 text-sm text-center mb-6">
                      История ваших заказов появится здесь
                    </p>
                    <button
                      onClick={() => setActiveTab('home')}
                      className="px-6 py-3 bg-red-500 text-white rounded-xl hover:bg-red-600 transition-colors"
                    >
                      Сделать заказ
                    </button>
                  </div>
                )}
              </div>

              {/* Cashback Info */}
              <div className="bg-gradient-to-br from-amber-50 to-orange-50 rounded-2xl p-6 mt-4 shadow-md border border-orange-100">
                <h3 className="text-lg mb-4 font-semibold">Система кэшбэка</h3>
                <div className="space-y-3 text-sm">
                  <div className="flex items-center justify-between py-2">
                    <span className="text-neutral-600">За каждый заказ</span>
                    <span className="font-semibold text-red-600">5% баллами</span>
                  </div>
                  <div className="flex items-center justify-between py-2">
                    <span className="text-neutral-600">1 балл равен</span>
                    <span className="font-semibold text-red-600">1 сўм</span>
                  </div>
                  <div className="flex items-center justify-between py-2">
                    <span className="text-neutral-600">Можно потратить</span>
                    <span className="font-semibold text-red-600">До 50% от заказа</span>
                  </div>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </main>

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-neutral-200 px-4 py-3 max-w-md mx-auto shadow-lg">
        <div className="flex items-center justify-around">
          <button
            onClick={() => setActiveTab('home')}
            className={`flex flex-col items-center gap-1 transition-all ${
              activeTab === 'home' ? 'text-red-500 scale-105' : 'text-neutral-400'
            }`}
          >
            <Home size={24} />
            <span className="text-xs font-medium">Меню</span>
          </button>

          <button
            onClick={() => setActiveTab('cart')}
            className={`flex flex-col items-center gap-1 transition-all relative ${
              activeTab === 'cart' ? 'text-red-500 scale-105' : 'text-neutral-400'
            }`}
          >
            <ShoppingCart size={24} />
            {totalItems > 0 && (
              <span className="absolute -top-1 -right-3 w-5 h-5 bg-red-500 text-white text-xs rounded-full flex items-center justify-center font-medium shadow-md">
                {totalItems}
              </span>
            )}
            <span className="text-xs font-medium">Корзина</span>
          </button>

          <button
            onClick={() => setActiveTab('profile')}
            className={`flex flex-col items-center gap-1 transition-all ${
              activeTab === 'profile' ? 'text-red-500 scale-105' : 'text-neutral-400'
            }`}
          >
            <User size={24} />
            <span className="text-xs font-medium">Профиль</span>
          </button>
        </div>
      </nav>

      {/* Menu QR Code Modal */}
      <AnimatePresence>
        {showMenuQR && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4"
            onClick={() => setShowMenuQR(false)}
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="bg-white rounded-3xl p-8 max-w-sm w-full shadow-2xl"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-xl font-semibold">Меню QR</h3>
                <button
                  onClick={() => setShowMenuQR(false)}
                  className="w-10 h-10 bg-neutral-100 rounded-full flex items-center justify-center hover:bg-neutral-200 transition-colors"
                >
                  <X size={20} />
                </button>
              </div>

              <div className="bg-gradient-to-br from-red-50 to-orange-50 rounded-2xl p-6 mb-6">
                <div className="bg-white rounded-xl p-4 flex justify-center">
                  <QRCodeSVG
                    value="https://enjolavash.uz/menu"
                    size={220}
                    level="H"
                    includeMargin={true}
                  />
                </div>
              </div>

              <p className="text-center text-neutral-600 text-sm">
                Отсканируйте QR-код для просмотра меню на вашем устройстве
              </p>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
