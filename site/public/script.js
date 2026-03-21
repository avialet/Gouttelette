/* ============================================
   GOUTTELETTE — Animations & Interactions
   GSAP + ScrollTrigger + ScrollToPlugin
   Pattern calqué sur Chuchotte
   ============================================ */

gsap.registerPlugin(ScrollTrigger, ScrollToPlugin);

// ─── Nav scroll effect ───
const nav = document.getElementById('nav');
ScrollTrigger.create({
  trigger: '.hero',
  start: 'top top',
  end: 'bottom top',
  onLeave: () => nav.classList.add('scrolled'),
  onEnterBack: () => nav.classList.remove('scrolled'),
});

// ─── Hero entrance animation ───
const heroTl = gsap.timeline({ defaults: { ease: 'power3.out' } });

heroTl
  .from('#hero-drop', {
    scale: 0,
    opacity: 0,
    duration: 1.4,
    ease: 'elastic.out(1, 0.5)',
  })
  .from('#hero-title', {
    y: 60,
    opacity: 0,
    duration: 1,
  }, '-=0.7')
  .from('#hero-tagline', {
    y: 40,
    opacity: 0,
    duration: 0.9,
  }, '-=0.6')
  .from('#hero-cta', {
    y: 30,
    opacity: 0,
    duration: 0.8,
  }, '-=0.5')
  .from('#scroll-indicator', {
    opacity: 0,
    y: -20,
    duration: 0.6,
  }, '-=0.3');

// ─── Features section ───

// Vertical gradient line draw
gsap.to('#features-line', {
  scrollTrigger: {
    trigger: '#features',
    start: 'top 90%',
    end: 'bottom 20%',
    scrub: 0.8,
  },
  scaleY: 1,
  ease: 'none',
});

// Header reveal
const featuresHeaderTl = gsap.timeline({
  scrollTrigger: {
    trigger: '#features',
    start: 'top 80%',
    once: true,
  },
});

featuresHeaderTl
  .from('#features-label', {
    y: 40,
    opacity: 0,
    duration: 0.8,
    ease: 'power3.out',
  })
  .from('#features-title', {
    y: 50,
    opacity: 0,
    duration: 1,
    ease: 'power3.out',
  }, '-=0.5');

// Feature cards — stagger from center with scale + rotation
gsap.from('.feature-card', {
  scrollTrigger: {
    trigger: '#features-grid',
    start: 'top 90%',
    once: true,
  },
  y: 80,
  opacity: 0,
  scale: 0.9,
  rotateX: 8,
  duration: 1,
  stagger: {
    amount: 0.8,
    from: 'center',
    grid: [2, 3],
  },
  ease: 'power4.out',
  transformPerspective: 800,
});

// Feature tags slide in after cards
gsap.from('.feature-tag', {
  scrollTrigger: {
    trigger: '#features-grid',
    start: 'top 75%',
    once: true,
  },
  x: -20,
  opacity: 0,
  duration: 0.6,
  stagger: {
    amount: 0.5,
    from: 'start',
  },
  delay: 0.6,
  ease: 'power2.out',
});

// Feature card numbers count up
document.querySelectorAll('.feature-number').forEach(num => {
  ScrollTrigger.create({
    trigger: num.closest('.feature-card'),
    start: 'top 80%',
    once: true,
    onEnter: () => {
      gsap.from(num, {
        textContent: '00',
        duration: 0.8,
        ease: 'power2.out',
        snap: { textContent: 1 },
        onUpdate() {
          const val = Math.round(parseFloat(num.textContent));
          num.textContent = String(val).padStart(2, '0');
        },
      });
    },
  });
});

// Feature card hover — 3D tilt + glow follow cursor
document.querySelectorAll('.feature-card').forEach(card => {
  const glow = card.querySelector('.feature-card-glow');

  card.addEventListener('mousemove', e => {
    const rect = card.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width - 0.5;
    const y = (e.clientY - rect.top) / rect.height - 0.5;

    gsap.to(card, {
      rotateY: x * 10,
      rotateX: -y * 10,
      duration: 0.4,
      ease: 'power2.out',
      transformPerspective: 800,
    });

    if (glow) {
      gsap.to(glow, {
        x: e.clientX - rect.left - 80,
        y: e.clientY - rect.top - 80,
        duration: 0.4,
        ease: 'power2.out',
      });
    }
  });

  card.addEventListener('mouseleave', () => {
    gsap.to(card, {
      rotateY: 0,
      rotateX: 0,
      duration: 0.8,
      ease: 'elastic.out(1, 0.4)',
    });
  });
});

// ─── Demo section ───
gsap.from('#demo-label', {
  scrollTrigger: {
    trigger: '#demo',
    start: 'top 80%',
    once: true,
  },
  y: 30,
  opacity: 0,
  duration: 0.7,
  ease: 'power2.out',
});

gsap.from('#demo-title', {
  scrollTrigger: {
    trigger: '#demo',
    start: 'top 80%',
    once: true,
  },
  y: 40,
  opacity: 0,
  duration: 0.8,
  delay: 0.15,
  ease: 'power2.out',
});

// Demo steps
const demoSteps = gsap.utils.toArray('.demo-step');
const demoConnectors = gsap.utils.toArray('.demo-connector');

demoSteps.forEach((step, i) => {
  gsap.from(step, {
    scrollTrigger: {
      trigger: '#demo-flow',
      start: 'top 80%',
      once: true,
    },
    y: 50,
    opacity: 0,
    duration: 0.8,
    delay: i * 0.25,
    ease: 'power3.out',
  });
});

demoConnectors.forEach((conn, i) => {
  gsap.from(conn, {
    scrollTrigger: {
      trigger: '#demo-flow',
      start: 'top 80%',
      once: true,
    },
    scaleX: 0,
    opacity: 0,
    duration: 0.6,
    delay: 0.15 + i * 0.25,
    ease: 'power2.out',
  });
});

// ─── Download section ───
gsap.from('#download-card', {
  scrollTrigger: {
    trigger: '#download',
    start: 'top 80%',
    once: true,
  },
  y: 60,
  opacity: 0,
  scale: 0.96,
  duration: 1,
  ease: 'power3.out',
});

// ─── Support section ───
gsap.from('#support-card', {
  scrollTrigger: {
    trigger: '#support',
    start: 'top 85%',
    once: true,
  },
  y: 40,
  opacity: 0,
  scale: 0.96,
  duration: 0.9,
  ease: 'power3.out',
});

// ─── Hero drop particle explosion on scroll ───
(() => {
  const dropContainer = document.getElementById('hero-drop');
  if (!dropContainer) return;

  const dropShape = dropContainer.querySelector('.drop-shape');
  const PARTICLE_COUNT = 40;
  const particles = [];

  // Create particles
  for (let i = 0; i < PARTICLE_COUNT; i++) {
    const p = document.createElement('div');
    p.className = 'drop-particle';
    const size = gsap.utils.random(8, 28);
    p.style.width = size + 'px';
    p.style.height = size + 'px';
    dropContainer.appendChild(p);

    // Random scatter destination
    const angle = (i / PARTICLE_COUNT) * Math.PI * 2 + gsap.utils.random(-0.4, 0.4);
    const distance = gsap.utils.random(120, 400);
    particles.push({
      el: p,
      tx: Math.cos(angle) * distance,
      ty: Math.sin(angle) * distance - gsap.utils.random(50, 200),
      rot: gsap.utils.random(-360, 360),
      scale: gsap.utils.random(0.3, 1),
    });
  }

  // Scrub timeline: drop shrinks + particles scatter
  const explodeTl = gsap.timeline({
    scrollTrigger: {
      trigger: '.hero',
      start: 'top top',
      end: '70% top',
      scrub: 0.8,
    },
  });

  // Main drop shrinks and fades
  explodeTl.to(dropShape, {
    scale: 0.3,
    opacity: 0,
    duration: 1,
    ease: 'none',
  }, 0);

  // Pulse rings fade
  explodeTl.to('.drop-pulse-ring', {
    opacity: 0,
    scale: 0.5,
    duration: 0.5,
    ease: 'none',
  }, 0);

  // Each particle flies out
  particles.forEach((p, i) => {
    const delay = (i / PARTICLE_COUNT) * 0.3;
    gsap.set(p.el, { opacity: 0, scale: 0 });

    explodeTl.fromTo(p.el,
      { x: 0, y: 0, opacity: 0, scale: 0, rotation: 0 },
      {
        x: p.tx,
        y: p.ty,
        opacity: 1,
        scale: p.scale,
        rotation: p.rot,
        duration: 1,
        ease: 'none',
      },
      delay
    );

    // Fade out particles at the end
    explodeTl.to(p.el, {
      opacity: 0,
      scale: 0,
      duration: 0.4,
      ease: 'none',
    }, 0.7 + delay * 0.5);
  });
})();

// ─── Hero content fade on scroll ───
gsap.to('.hero-content', {
  scrollTrigger: {
    trigger: '.hero',
    start: 'center center',
    end: 'bottom top',
    scrub: 1,
  },
  y: -80,
  opacity: 0,
  ease: 'none',
});

// ─── Smooth scroll for anchor links ───
document.querySelectorAll('a[href^="#"]').forEach(link => {
  link.addEventListener('click', e => {
    e.preventDefault();
    const target = document.querySelector(link.getAttribute('href'));
    if (target) {
      gsap.to(window, {
        scrollTo: { y: target, offsetY: 40 },
        duration: 1,
        ease: 'power3.inOut',
      });
    }
  });
});

// ─── Magnetic button effect ───
document.querySelectorAll('.btn-primary').forEach(btn => {
  btn.addEventListener('mousemove', e => {
    const rect = btn.getBoundingClientRect();
    const x = e.clientX - rect.left - rect.width / 2;
    const y = e.clientY - rect.top - rect.height / 2;

    gsap.to(btn, {
      x: x * 0.15,
      y: y * 0.15,
      duration: 0.3,
      ease: 'power2.out',
    });
  });

  btn.addEventListener('mouseleave', () => {
    gsap.to(btn, {
      x: 0,
      y: 0,
      duration: 0.5,
      ease: 'elastic.out(1, 0.4)',
    });
  });
});

// ─── Glow follow cursor on hero ───
const heroGlow = document.querySelector('.hero-glow');
if (heroGlow) {
  document.querySelector('.hero').addEventListener('mousemove', e => {
    gsap.to(heroGlow, {
      x: (e.clientX - window.innerWidth / 2) * 0.08,
      y: (e.clientY - window.innerHeight / 2) * 0.08,
      duration: 1.5,
      ease: 'power2.out',
    });
  });
}
