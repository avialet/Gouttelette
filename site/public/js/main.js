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
    el.style.transform = sel === '#hero-blob' ? 'scale(0.8)' : 'translateY(40px)';
  }
});

requestAnimationFrame(() => {
  const heroTl = gsap.timeline({ defaults: { ease: 'power3.out' } });
  heroTl
    .to('#hero-blob', { scale: 1, opacity: 1, duration: 1.2, ease: 'power3.out' })
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

// Animate feature cards on scroll
gsap.utils.toArray('.feature-card').forEach((card, i) => {
  gsap.from(card, {
    scrollTrigger: { trigger: card, start: 'top 90%', once: true },
    y: 40, opacity: 0, scale: 0.95, duration: 0.6, delay: i * 0.1,
    ease: 'power3.out',
  });
});

// Parallax hero content on scroll
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
