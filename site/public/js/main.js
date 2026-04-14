gsap.registerPlugin(ScrollTrigger, ScrollToPlugin);

const nav = document.getElementById('nav');
ScrollTrigger.create({
  trigger: '.hero',
  start: 'top top',
  end: 'bottom top',
  onLeave: () => nav.classList.add('scrolled'),
  onEnterBack: () => nav.classList.remove('scrolled'),
});

const heroElements = ['#hero-blob', '#hero-title', '#hero-tagline', '#hero-cta', '#scroll-indicator'];
heroElements.forEach(sel => {
  const el = document.querySelector(sel);
  if (el) {
    el.style.opacity = '0';
    el.style.transform = sel === '#hero-blob' ? 'scale(0)' : 'translateY(40px)';
  }
});

requestAnimationFrame(() => {
  const heroTl = gsap.timeline({ defaults: { ease: 'power3.out' } });
  heroTl
    .to('#hero-blob', { scale: 1, opacity: 1, duration: 1.4, ease: 'elastic.out(1, 0.5)' })
    .to('#hero-title', { y: 0, opacity: 1, duration: 1 }, '-=0.7')
    .to('#hero-tagline', { y: 0, opacity: 1, duration: 0.9 }, '-=0.6')
    .to('#hero-cta', { y: 0, opacity: 1, duration: 0.8 }, '-=0.5')
    .to('#scroll-indicator', { opacity: 1, y: 0, duration: 0.6 }, '-=0.3');
});

gsap.from('#download-card', {
  scrollTrigger: { trigger: '#download', start: 'top 80%', once: true },
  y: 60, opacity: 0, scale: 0.96, duration: 1, ease: 'power3.out',
});

gsap.from('#support-card', {
  scrollTrigger: { trigger: '#support', start: 'top 85%', once: true },
  y: 40, opacity: 0, scale: 0.96, duration: 0.9, ease: 'power3.out',
});

(() => {
  const blobContainer = document.getElementById('hero-blob');
  if (!blobContainer) return;
  const blobShape = blobContainer.querySelector('.blob-shape');
  const PARTICLE_COUNT = 40;
  const particles = [];

  for (let i = 0; i < PARTICLE_COUNT; i++) {
    const p = document.createElement('div');
    p.className = 'blob-particle';
    const size = gsap.utils.random(8, 28);
    p.style.width = size + 'px';
    p.style.height = size + 'px';
    blobContainer.appendChild(p);
    const angle = (i / PARTICLE_COUNT) * Math.PI * 2 + gsap.utils.random(-0.4, 0.4);
    const distance = gsap.utils.random(120, 400);
    particles.push({ el: p, tx: Math.cos(angle) * distance, ty: Math.sin(angle) * distance - gsap.utils.random(50, 200), rot: gsap.utils.random(-360, 360), scale: gsap.utils.random(0.3, 1) });
  }

  const explodeTl = gsap.timeline({
    scrollTrigger: { trigger: '.hero', start: 'top top', end: '70% top', scrub: 0.8 },
  });

  explodeTl.to(blobShape, { scale: 0.3, opacity: 0, duration: 1, ease: 'none' }, 0);
  explodeTl.to('.blob-pulse-ring', { opacity: 0, scale: 0.5, duration: 0.5, ease: 'none' }, 0);

  particles.forEach((p, i) => {
    const delay = (i / PARTICLE_COUNT) * 0.3;
    gsap.set(p.el, { opacity: 0, scale: 0 });
    explodeTl.fromTo(p.el, { x: 0, y: 0, opacity: 0, scale: 0, rotation: 0 }, { x: p.tx, y: p.ty, opacity: 1, scale: p.scale, rotation: p.rot, duration: 1, ease: 'none' }, delay);
    explodeTl.to(p.el, { opacity: 0, scale: 0, duration: 0.4, ease: 'none' }, 0.7 + delay * 0.5);
  });
})();

gsap.to('.hero-content', {
  scrollTrigger: { trigger: '.hero', start: 'center center', end: 'bottom top', scrub: 1 },
  y: -80, opacity: 0, ease: 'none',
});

document.querySelectorAll('a[href^="#"]').forEach(link => {
  link.addEventListener('click', e => {
    e.preventDefault();
    const target = document.querySelector(link.getAttribute('href'));
    if (target) gsap.to(window, { scrollTo: { y: target, offsetY: 40 }, duration: 1, ease: 'power3.inOut' });
  });
});

const heroGlow = document.querySelector('.hero-glow');
if (heroGlow) {
  document.querySelector('.hero').addEventListener('mousemove', e => {
    gsap.to(heroGlow, { x: (e.clientX - window.innerWidth / 2) * 0.08, y: (e.clientY - window.innerHeight / 2) * 0.08, duration: 1.5, ease: 'power2.out' });
  });
}
