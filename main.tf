terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.40.0"
    }
  }
}

provider "aws" {
  region = ap-south-1
}

data "aws_vpc" "default" {
    default = true 
}

data "aws_subnets" "default" {
    filter {
      name = "vpc-id"
      values = [ data.aws_vpc.default.id ]
    }
}

resource "tls_private_key" "ec2-key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name = "generated_key_by_terraform"
  public_key = tls_private_key.ec2-key.public_key_openssh
}

resource "local_file" "aws_private_key_pem" {
  content = tls_private_key.ec2-key.private_key_pem
  filename = "${path.module}/aws/generated_key_by_terraform.pem"
  file_permission = "0400"
  directory_permission = "0700"
}

resource "aws_security_group" "http_server_sg" {
  name        = "http_server_sg"
  description = "Allow HTTP traffic"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  tags = {
    Name = "http_server_sg"
  }
}

resource "aws_instance" "http_server" {
  ami = ami-048f4445314bcaa09
  instance_type = "t2.medium"
  key_name = aws_key_pair.generated_key.key_name
  subnet_id = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.http_server_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash

    yum update -y
    yum install httpd -y

    systemctl start httpd
    systemctl enable httpd

    # Create index.html
    cat <<'HTML' > /var/www/html/index.html

    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Zest Zumba Studio</title>

      <!-- Google Font -->
      <link
        href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap"
        rel="stylesheet"
      />

      <!-- Main Styles -->
      <link rel="stylesheet" href="style.css" />
    </head>
    <body>
      <!-- Animated background shapes -->
      <div class="bg-shape bg-shape-1"></div>
      <div class="bg-shape bg-shape-2"></div>
      <div class="bg-shape bg-shape-3"></div>

      <!-- Header -->
      <header class="header">
        <div class="container header-inner">
          <div class="logo">
            <span class="logo-icon">Z</span>
            <span class="logo-text">Zest Zumba Studio</span>
          </div>

          <nav class="nav">
            <a href="#hero">Home</a>
            <a href="#about">About</a>
            <a href="#benefits">Benefits</a>
            <a href="#classes">Classes</a>
            <a href="#pricing">Pricing</a>
            <a href="#contact" class="nav-cta">Join Now</a>
          </nav>
        </div>
      </header>

      <!-- Hero Section -->
      <section id="hero" class="hero">
        <div class="container hero-inner">
          <div class="hero-content">
            <p class="hero-tag">Feel the Beat · Burn the Calories</p>
            <h1>
              Dance your way to
              <span class="highlight">fitness & joy</span>
            </h1>
            <p class="hero-subtitle">
              High-energy Zumba classes that feel more like a party than a workout.
              No experience needed — just bring your vibe!
            </p>

            <div class="hero-actions">
              <a href="#contact" class="btn btn-primary">
                Book Free Trial
              </a>
              <a href="#classes" class="btn btn-ghost">
                View Class Schedule
              </a>
            </div>

            <div class="hero-stats">
              <div class="stat">
                <span class="stat-number">+120</span>
                <span class="stat-label">Happy Members</span>
              </div>
              <div class="stat">
                <span class="stat-number">7</span>
                <span class="stat-label">Days a Week</span>
              </div>
              <div class="stat">
                <span class="stat-number">45 min</span>
                <span class="stat-label">Per Session</span>
              </div>
            </div>
          </div>

          <div class="hero-visual">
            <div class="hero-card floating">
              <div class="hero-avatar"></div>
              <p class="hero-quote">
                “Best part of my day! I lost 6kg and made new friends.”
              </p>
              <span class="hero-name">— Riya, Member</span>
            </div>

            <div class="hero-badge pulse">
              <span class="badge-label">New</span>
              <span class="badge-text">First Class Free</span>
            </div>

            <div class="hero-circle hero-circle-1"></div>
            <div class="hero-circle hero-circle-2"></div>
            <div class="hero-circle hero-circle-3"></div>
          </div>
        </div>
      </section>

      <!-- About -->
      <section id="about" class="section">
        <div class="container grid-2">
          <div>
            <h2>What is Zumba?</h2>
            <p>
              Zumba is a fun, music-driven workout that mixes low-intensity and
              high-intensity moves for an interval-style, calorie-burning dance
              fitness party.
            </p>
            <p>
              At <strong>Zest Zumba Studio</strong>, we keep the moves simple and
              the energy high — so you can de-stress, sweat, and smile all at the
              same time.
            </p>
          </div>
          <div class="about-highlights">
            <div class="about-card">
              <h3>Beginner Friendly</h3>
              <p>No dance background needed. Just follow the vibe and have fun.</p>
            </div>
            <div class="about-card">
              <h3>Certified Instructors</h3>
              <p>Our trainers are experienced and internationally certified.</p>
            </div>
            <div class="about-card">
              <h3>Studio & Online</h3>
              <p>Join us at the studio or sweat it out from home.</p>
            </div>
          </div>
        </div>
      </section>

      <!-- Benefits -->
      <section id="benefits" class="section section-alt">
        <div class="container">
          <h2 class="section-title">Why you'll love our classes</h2>
          <p class="section-subtitle">
            More than just burning calories — it's a mood booster.
          </p>

          <div class="grid-3">
            <div class="benefit-card">
              <span class="benefit-icon">🔥</span>
              <h3>Burn Calories</h3>
              <p>
                Up to 600–800 calories per class with full-body movement and fun
                choreography.
              </p>
            </div>
            <div class="benefit-card">
              <span class="benefit-icon">😊</span>
              <h3>Boost Your Mood</h3>
              <p>
                Latin & world rhythms that instantly lift your spirit and reduce
                stress.
              </p>
            </div>
            <div class="benefit-card">
              <span class="benefit-icon">🤝</span>
              <h3>Community Vibes</h3>
              <p>
                Supportive group environment where everyone is welcome and
                encouraged.
              </p>
            </div>
          </div>
        </div>
      </section>

      <!-- Classes / Schedule -->
      <section id="classes" class="section">
        <div class="container">
          <h2 class="section-title">Class schedule</h2>
          <p class="section-subtitle">
            Pick a time that fits your energy. All sessions are 45 minutes.
          </p>

          <div class="schedule">
            <div class="schedule-item">
              <h3>Morning Boost</h3>
              <p class="schedule-time">6:30 AM · Mon, Wed, Fri</p>
              <p>Start your day with high vibes and fresh energy.</p>
            </div>
            <div class="schedule-item">
              <h3>Evening Party</h3>
              <p class="schedule-time">7:00 PM · Tue, Thu, Sat</p>
              <p>Let go of your day and dance it out with the crew.</p>
            </div>
            <div class="schedule-item">
              <h3>Sunday Mix</h3>
              <p class="schedule-time">9:00 AM · Sunday</p>
              <p>Special playlists, slower pace, and extra stretching.</p>
            </div>
          </div>
        </div>
      </section>

      <!-- Pricing -->
      <section id="pricing" class="section section-alt">
        <div class="container">
          <h2 class="section-title">Simple pricing</h2>
          <p class="section-subtitle">
          Try a free class, then choose the plan that feels right.
          </p>

          <div class="pricing-grid">
            <div class="price-card">
              <h3>Drop-In</h3>
              <p class="price-tag">₹399</p>
              <p class="price-note">per class</p>
              <ul>
                <li>Access to any single class</li>
                <li>Perfect for busy schedules</li>
                <li>No commitment</li>
              </ul>
              <a href="#contact" class="btn btn-outline">Try Once</a>
            </div>

            <div class="price-card price-card-featured">
              <div class="price-label">Popular</div>
              <h3>Monthly Unlimited</h3>
              <p class="price-tag">₹2,499</p>
              <p class="price-note">per month</p>
              <ul>
                <li>Unlimited studio classes</li>
                <li>Access to online sessions</li>
                <li>Priority booking</li>
              </ul>
              <a href="#contact" class="btn btn-primary full-width">
                Join Membership
              </a>
            </div>

            <div class="price-card">
              <h3>10-Class Pack</h3>
              <p class="price-tag">₹1,999</p>
              <p class="price-note">valid for 6 weeks</p>
              <ul>
                <li>Any 10 studio classes</li>
                <li>Flexible timings</li>
                <li>Ideal for beginners</li>
              </ul>
              <a href="#contact" class="btn btn-outline">Get Pack</a>
            </div>
          </div>
        </div>
      </section>

      <!-- Testimonials -->
      <section id="testimonials" class="section">
        <div class="container">
          <h2 class="section-title">What our members say</h2>

          <div class="testimonial-grid">
            <div class="testimonial-card">
              <p>
                “I used to hate working out. Now I look forward to every Zumba
                session!”
              </p>
              <span class="testimonial-name">Aman, Software Engineer</span>
            </div>
            <div class="testimonial-card">
              <p>
                “The instructors are so positive and encouraging. The playlist is
                🔥.”
              </p>
              <span class="testimonial-name">Priya, Student</span>
            </div>
            <div class="testimonial-card">
              <p>
                “Lost inches, gained confidence. The best stress-buster after work.”
              </p>
              <span class="testimonial-name">Neha, Marketing Professional</span>
            </div>
          </div>
        </div>
      </section>

      <!-- Contact -->
      <section id="contact" class="section section-alt">
        <div class="container contact-grid">
          <div>
            <h2>Book your free trial class</h2>
            <p>
              Share your details and we’ll get back to you with available slots and
              membership options.
            </p>

            <div class="contact-info">
              <p><strong>Location:</strong> Zest Zumba Studio, Your City</p>
              <p><strong>WhatsApp:</strong> +91-90000-00000</p>
              <p><strong>Email:</strong> hello@zestzumba.com</p>
            </div>
          </div>

          <form class="contact-form">
            <div class="form-group">
              <label for="name">Full Name</label>
              <input id="name" type="text" placeholder="Enter your name" />
            </div>

            <div class="form-group">
              <label for="email">Email</label>
              <input id="email" type="email" placeholder="you@example.com" />
            </div>

            <div class="form-group">
              <label for="phone">Phone / WhatsApp</label>
              <input id="phone" type="tel" placeholder="+91-" />
            </div>

            <div class="form-group">
              <label for="slot">Preferred Time</label>
              <select id="slot">
                <option>Morning · 6:30 AM</option>
                <option>Evening · 7:00 PM</option>
                <option>Sunday · 9:00 AM</option>
                <option>Flexible / Not sure yet</option>
              </select>
            </div>

            <div class="form-group">
              <label for="message">Goals (optional)</label>
              <textarea
                id="message"
                rows="3"
                placeholder="Weight loss, stress relief, fun workout, etc."
              ></textarea>
            </div>

            <button type="submit" class="btn btn-primary full-width">
              Send Request
            </button>
          </form>
        </div>
      </section>

      <!-- Footer -->
      <footer class="footer">
        <div class="container footer-inner">
          <p>© <span id="year">2025</span> Zest Zumba Studio. All rights reserved.</p>
          <p class="footer-note">Made with 💃, sweat, and good vibes.</p>
        </div>
      </footer>
    </body>
    </html>

    HTML

    # Create style.css
    cat <<'CSS' > /var/www/html/style.css

    /* =========
      Base
      ========= */
    :root {
      --bg: #050816;
      --bg-alt: rgba(9, 9, 25, 0.9);
      --card: rgba(15, 18, 46, 0.95);
      --card-alt: rgba(19, 24, 63, 0.98);
      --accent: #ff4f8b;
      --accent-soft: rgba(255, 79, 139, 0.15);
      --accent-yellow: #ffd166;
      --text: #f9fafb;
      --muted: #9ca3af;
      --border: rgba(148, 163, 184, 0.3);
      --radius-lg: 24px;
      --radius-xl: 999px;
      --shadow-soft: 0 18px 45px rgba(0, 0, 0, 0.45);
      --shadow-card: 0 18px 40px rgba(15, 23, 42, 0.7);
    }

    *,
    *::before,
    *::after {
      box-sizing: border-box;
    }

    html {
      scroll-behavior: smooth;
    }

    body {
      margin: 0;
      min-height: 100vh;
      font-family: "Poppins", system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
      background: radial-gradient(circle at top left, #111827 0, #020617 50%, #020617 100%);
      color: var(--text);
      position: relative;
      overflow-x: hidden;
    }

    /* Container */
    .container {
      width: min(1120px, 100% - 32px);
      margin: 0 auto;
    }

    /* =========
      Background Animated Shapes
      ========= */
    .bg-shape {
      position: fixed;
      filter: blur(80px);
      opacity: 0.5;
      z-index: -2;
      border-radius: 999px;
      pointer-events: none;
    }

    .bg-shape-1 {
      width: 320px;
      height: 320px;
      background: #ff4f8b;
      top: -80px;
      right: -40px;
      animation: float 18s ease-in-out infinite alternate;
    }

    .bg-shape-2 {
      width: 260px;
      height: 260px;
      background: #38bdf8;
      bottom: -60px;
      left: -80px;
      animation: float 24s ease-in-out infinite alternate-reverse;
    }

    .bg-shape-3 {
      width: 220px;
      height: 220px;
      background: #a855f7;
      top: 30%;
      left: 10%;
      animation: float 30s ease-in-out infinite alternate;
    }

    @keyframes float {
      0% {
        transform: translate3d(0, 0, 0) scale(1);
      }
      50% {
        transform: translate3d(40px, -30px, 0) scale(1.05);
      }
      100% {
        transform: translate3d(-40px, 20px, 0) scale(0.98);
      }
    }

    /* =========
      Header
      ========= */
    .header {
      position: sticky;
      top: 0;
      z-index: 50;
      backdrop-filter: blur(22px);
      background: linear-gradient(
        to bottom,
        rgba(15, 23, 42, 0.95),
        rgba(15, 23, 42, 0.7),
        transparent
      );
      border-bottom: 1px solid rgba(148, 163, 184, 0.25);
    }

    .header-inner {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 14px 0;
    }

    .logo {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .logo-icon {
      width: 34px;
      height: 34px;
      border-radius: 14px;
      background: radial-gradient(circle at 10% 0, #ff4f8b, #f97316);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-weight: 700;
      letter-spacing: 1px;
      box-shadow: 0 8px 22px rgba(248, 113, 113, 0.65);
    }

    .logo-text {
      font-weight: 600;
      letter-spacing: 0.04em;
      font-size: 0.96rem;
    }

    .nav {
      display: flex;
      align-items: center;
      gap: 20px;
    }

    .nav a {
      font-size: 0.9rem;
      text-decoration: none;
      color: var(--muted);
      padding: 6px 10px;
      border-radius: 999px;
      transition: color 0.2s ease, background 0.2s ease, transform 0.15s ease;
    }

    .nav a:hover {
      color: var(--text);
      background: rgba(148, 163, 184, 0.12);
      transform: translateY(-1px);
    }

    .nav-cta {
      border: 1px solid rgba(248, 113, 113, 0.7);
      background: radial-gradient(circle at top left, rgba(248, 113, 113, 0.35), transparent);
      color: var(--text);
    }

    /* =========
      Hero
      ========= */
    .hero {
      padding: 72px 0 72px;
    }

    .hero-inner {
      display: grid;
      grid-template-columns: minmax(0, 1.25fr) minmax(0, 1fr);
      gap: 48px;
      align-items: center;
    }

    .hero-tag {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 4px 10px;
      border-radius: 999px;
      background: rgba(17, 24, 39, 0.8);
      border: 1px solid rgba(148, 163, 184, 0.3);
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 0.12em;
      color: var(--muted);
      animation: fadeInUp 0.5s ease-out;
    }

    .hero-tag::before {
      content: "";
      width: 6px;
      height: 6px;
      border-radius: 999px;
      background: #22c55e;
      box-shadow: 0 0 0 6px rgba(34, 197, 94, 0.15);
    }

    .hero h1 {
      font-size: clamp(2.4rem, 5vw, 3.5rem);
      line-height: 1.1;
      margin: 18px 0 14px;
      letter-spacing: 0.02em;
      animation: fadeInUp 0.7s ease-out;
    }

    .highlight {
      background: linear-gradient(to right, #ff4f8b, #f97316, #fde68a);
      -webkit-background-clip: text;
      color: transparent;
    }

    .hero-subtitle {
      max-width: 520px;
      color: var(--muted);
      font-size: 0.98rem;
      animation: fadeInUp 0.9s ease-out;
    }

    .hero-actions {
      display: flex;
      flex-wrap: wrap;
      gap: 14px;
      margin-top: 20px;
      margin-bottom: 18px;
      animation: fadeInUp 1.1s ease-out;
    }

    /* Buttons */
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      padding: 10px 20px;
      border-radius: var(--radius-xl);
      border: none;
      outline: none;
      cursor: pointer;
      text-decoration: none;
      font-size: 0.9rem;
      font-weight: 500;
      transition: transform 0.16s ease, box-shadow 0.16s ease, background 0.16s ease,
        color 0.16s ease, border 0.16s ease;
    }

    .btn-primary {
      background: linear-gradient(135deg, #ff4f8b, #f97316);
      box-shadow: 0 16px 32px rgba(248, 113, 113, 0.55);
      color: #0b1020;
    }

    .btn-primary:hover {
      transform: translateY(-2px) scale(1.02);
      box-shadow: 0 22px 42px rgba(248, 113, 113, 0.8);
    }

    .btn-ghost {
      background: rgba(15, 23, 42, 0.8);
      color: var(--text);
      border: 1px solid rgba(148, 163, 184, 0.4);
    }

    .btn-ghost:hover {
      background: rgba(15, 23, 42, 1);
      transform: translateY(-2px);
    }

    .btn-outline {
      border: 1px solid rgba(248, 250, 252, 0.35);
      background: transparent;
      color: var(--text);
    }

    .btn-outline:hover {
      background: rgba(15, 23, 42, 0.9);
    }

    .full-width {
      width: 100%;
    }

    /* Hero stats */
    .hero-stats {
      display: flex;
      flex-wrap: wrap;
      gap: 16px;
      margin-top: 6px;
      animation: fadeInUp 1.3s ease-out;
    }

    .stat {
      padding: 10px 14px;
      border-radius: 17px;
      border: 1px solid rgba(148, 163, 184, 0.3);
      background: rgba(15, 23, 42, 0.8);
      min-width: 110px;
    }

    .stat-number {
      display: block;
      font-weight: 600;
      font-size: 1.1rem;
    }

    .stat-label {
      display: block;
      font-size: 0.75rem;
      color: var(--muted);
    }

    /* Hero visual */
    .hero-visual {
      position: relative;
      min-height: 260px;
    }

    .hero-card {
      position: relative;
      z-index: 2;
      padding: 20px;
      background: radial-gradient(circle at top left, #1f2937, #020617);
      border-radius: 28px;
      box-shadow: var(--shadow-card);
      border: 1px solid rgba(148, 163, 184, 0.3);
      max-width: 300px;
      margin-left: auto;
    }

    .hero-avatar {
      width: 46px;
      height: 46px;
      border-radius: 999px;
      background: linear-gradient(135deg, #f97316, #fde68a);
      margin-bottom: 10px;
      position: relative;
      overflow: hidden;
    }

    .hero-avatar::before {
      content: "";
      position: absolute;
      inset: 6px;
      border-radius: inherit;
      background: radial-gradient(circle at 30% 20%, #020617, #111827);
    }

    .hero-quote {
      font-size: 0.88rem;
      color: var(--text);
      margin: 2px 0 6px;
    }

    .hero-name {
      font-size: 0.75rem;
      color: var(--muted);
    }

    .hero-badge {
      position: absolute;
      top: 12%;
      left: -10px;
      padding: 8px 14px;
      border-radius: 999px;
      background: rgba(15, 23, 42, 0.96);
      border: 1px solid rgba(248, 250, 252, 0.18);
      display: inline-flex;
      flex-direction: column;
      gap: 2px;
      box-shadow: var(--shadow-soft);
    }

    .badge-label {
      font-size: 0.68rem;
      text-transform: uppercase;
      letter-spacing: 0.14em;
      color: var(--muted);
    }

    .badge-text {
      font-size: 0.8rem;
      font-weight: 500;
      color: var(--accent-yellow);
    }

    /* Animated circles */
    .hero-circle {
      position: absolute;
      border-radius: 999px;
      border: 1px solid rgba(148, 163, 184, 0.5);
      background: radial-gradient(circle at 20% 0, rgba(148, 163, 184, 0.2), transparent);
      backdrop-filter: blur(12px);
    }

    .hero-circle-1 {
      width: 220px;
      height: 220px;
      top: 10%;
      right: -40px;
      animation: orbit 18s linear infinite;
    }

    .hero-circle-2 {
      width: 140px;
      height: 140px;
      bottom: -20px;
      right: 60px;
      animation: floatSoft 14s ease-in-out infinite;
    }

    .hero-circle-3 {
      width: 80px;
      height: 80px;
      bottom: 60px;
      left: 10px;
      animation: floatSoft 11s ease-in-out infinite reverse;
    }

    /* Animations */
    .floating {
      animation: floatingCard 9s ease-in-out infinite;
    }

    .pulse {
      animation: pulseBadge 2.6s ease-out infinite;
    }

    @keyframes floatingCard {
      0%,
      100% {
        transform: translateY(0) translateX(0);
      }
      50% {
        transform: translateY(-10px) translateX(-4px);
      }
    }

    @keyframes pulseBadge {
      0% {
        transform: scale(1);
        box-shadow: 0 0 0 0 rgba(251, 191, 36, 0.35);
      }
      70% {
        transform: scale(1.03);
        box-shadow: 0 0 0 16px rgba(251, 191, 36, 0);
      }
      100% {
        transform: scale(1);
        box-shadow: 0 0 0 0 rgba(251, 191, 36, 0);
      }
    }

    @keyframes orbit {
      0% {
        transform: rotate(0deg) translateX(0);
      }
      50% {
        transform: rotate(180deg) translateX(10px);
      }
      100% {
        transform: rotate(360deg) translateX(0);
      }
    }

    @keyframes floatSoft {
      0% {
        transform: translate3d(0, 0, 0);
      }
      50% {
        transform: translate3d(12px, -14px, 0);
      }
      100% {
        transform: translate3d(-6px, 10px, 0);
      }
    }

    @keyframes fadeInUp {
      from {
        opacity: 0;
        transform: translateY(14px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    /* =========
      Sections
      ========= */
    .section {
      padding: 54px 0;
    }

    .section-alt {
      background: radial-gradient(circle at top, rgba(15, 23, 42, 0.95), rgba(15, 23, 42, 0.92));
      border-top: 1px solid rgba(51, 65, 85, 0.7);
      border-bottom: 1px solid rgba(30, 64, 175, 0.6);
    }

    .section-title {
      font-size: 1.6rem;
      margin-bottom: 4px;
    }

    .section-subtitle {
      color: var(--muted);
      font-size: 0.95rem;
      margin-bottom: 26px;
    }

    /* Layout grids */
    .grid-2 {
      display: grid;
      grid-template-columns: minmax(0, 1.1fr) minmax(0, 1fr);
      gap: 32px;
      align-items: start;
    }

    .grid-3 {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 20px;
    }

    /* About */
    .about-highlights {
      display: grid;
      gap: 14px;
    }

    .about-card {
      padding: 16px 16px 14px;
      background: rgba(15, 23, 42, 0.9);
      border-radius: 18px;
      border: 1px solid rgba(148, 163, 184, 0.3);
      box-shadow: 0 10px 24px rgba(15, 23, 42, 0.6);
      font-size: 0.9rem;
    }

    /* Benefits */
    .benefit-card {
      padding: 18px 16px 16px;
      background: rgba(15, 23, 42, 0.9);
      border-radius: 22px;
      border: 1px solid rgba(148, 163, 184, 0.4);
      box-shadow: 0 18px 40px rgba(15, 23, 42, 0.9);
      position: relative;
      overflow: hidden;
    }

    .benefit-card::before {
      content: "";
      position: absolute;
      inset: 0;
      background: radial-gradient(circle at top left, rgba(248, 113, 113, 0.25), transparent);
      opacity: 0;
      transition: opacity 0.25s ease;
    }

    .benefit-card:hover::before {
      opacity: 1;
    }

    .benefit-icon {
      font-size: 1.4rem;
      margin-bottom: 4px;
    }

    .benefit-card h3 {
      margin: 0 0 4px;
      font-size: 1rem;
    }

    .benefit-card p {
      margin: 0;
      font-size: 0.89rem;
      color: var(--muted);
    }

    /* Schedule */
    .schedule {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 18px;
    }

    .schedule-item {
      padding: 18px 16px 16px;
      background: rgba(15, 23, 42, 0.96);
      border-radius: 18px;
      border: 1px solid rgba(148, 163, 184, 0.5);
      box-shadow: 0 16px 32px rgba(15, 23, 42, 0.85);
      font-size: 0.9rem;
    }

    .schedule-item h3 {
      margin: 0 0 4px;
      font-size: 1rem;
    }

    .schedule-time {
      margin: 0 0 6px;
      color: var(--accent-yellow);
      font-size: 0.86rem;
    }

    /* Pricing */
    .pricing-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 20px;
      align-items: stretch;
    }

    .price-card {
      position: relative;
      padding: 22px 18px 18px;
      background: rgba(15, 23, 42, 0.98);
      border-radius: 22px;
      border: 1px solid rgba(148, 163, 184, 0.5);
      box-shadow: 0 18px 40px rgba(15, 23, 42, 1);
      font-size: 0.9rem;
    }

    .price-card h3 {
      margin: 0 0 4px;
    }

    .price-tag {
      font-size: 1.4rem;
      font-weight: 600;
      margin: 4px 0;
    }

    .price-note {
      margin: 0 0 10px;
      color: var(--muted);
      font-size: 0.82rem;
    }

    .price-card ul {
      list-style: none;
      padding: 0;
      margin: 0 0 16px;
    }

    .price-card li {
      font-size: 0.85rem;
      color: var(--muted);
      margin-bottom: 6px;
    }

    .price-card-featured {
      border-color: rgba(248, 250, 252, 0.8);
      transform: translateY(-6px);
      background: radial-gradient(circle at top, rgba(15, 23, 42, 1), rgba(15, 23, 42, 0.96));
    }

    .price-card-featured:hover {
      transform: translateY(-10px);
    }

    .price-label {
      position: absolute;
      top: 12px;
      right: 14px;
      font-size: 0.7rem;
      text-transform: uppercase;
      letter-spacing: 0.16em;
      padding: 4px 9px;
      border-radius: 999px;
      background: rgba(22, 163, 74, 0.1);
      color: #bbf7d0;
      border: 1px solid rgba(34, 197, 94, 0.7);
    }

    /* Testimonials */
    .testimonial-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 16px;
    }

    .testimonial-card {
      padding: 16px 16px 14px;
      background: rgba(15, 23, 42, 0.96);
      border-radius: 20px;
      border: 1px solid rgba(148, 163, 184, 0.45);
      box-shadow: 0 16px 32px rgba(15, 23, 42, 0.9);
      font-size: 0.9rem;
    }

    .testimonial-card p {
      margin: 0 0 8px;
    }

    .testimonial-name {
      font-size: 0.8rem;
      color: var(--muted);
    }

    /* Contact */
    .contact-grid {
      display: grid;
      grid-template-columns: minmax(0, 1.05fr) minmax(0, 1fr);
      gap: 32px;
      align-items: start;
    }

    .contact-info p {
      margin: 6px 0;
      font-size: 0.9rem;
      color: var(--muted);
    }

    .contact-form {
      padding: 18px 18px 16px;
      background: rgba(15, 23, 42, 0.98);
      border-radius: 22px;
      border: 1px solid rgba(148, 163, 184, 0.5);
      box-shadow: 0 18px 40px rgba(15, 23, 42, 1);
    }

    .form-group {
      margin-bottom: 10px;
    }

    .form-group label {
      display: block;
      font-size: 0.82rem;
      margin-bottom: 4px;
      color: var(--muted);
    }

    input,
    select,
    textarea {
      width: 100%;
      border-radius: 12px;
      border: 1px solid rgba(148, 163, 184, 0.6);
      background: rgba(15, 23, 42, 0.9);
      color: var(--text);
      padding: 8px 10px;
      font-family: inherit;
      font-size: 0.88rem;
      outline: none;
      transition: border 0.16s ease, box-shadow 0.16s ease, background 0.16s ease;
    }

    input::placeholder,
    textarea::placeholder {
      color: rgba(148, 163, 184, 0.8);
    }

    input:focus,
    select:focus,
    textarea:focus {
      border-color: rgba(248, 113, 113, 0.7);
      box-shadow: 0 0 0 1px rgba(248, 113, 113, 0.4);
      background: rgba(15, 23, 42, 0.95);
    }

    /* Footer */
    .footer {
      border-top: 1px solid rgba(51, 65, 85, 0.9);
      padding: 14px 0 22px;
      background: radial-gradient(circle at top, rgba(15, 23, 42, 0.98), rgba(15, 23, 42, 1));
    }

    .footer-inner {
      text-align: center;
      font-size: 0.8rem;
      color: var(--muted);
    }

    .footer-note {
      margin-top: 4px;
      font-size: 0.78rem;
    }

    /* =========
      Responsive
      ========= */
    @media (max-width: 900px) {
      .hero-inner {
        grid-template-columns: minmax(0, 1fr);
      }

      .hero-visual {
        order: -1;
      }

      .grid-2,
      .pricing-grid,
      .schedule,
      .testimonial-grid,
      .contact-grid,
      .grid-3 {
        grid-template-columns: minmax(0, 1fr);
      }

      .price-card-featured {
        transform: none;
      }

      .header-inner {
        gap: 16px;
      }

      .nav {
        gap: 8px;
        font-size: 0.8rem;
      }

      .nav a {
        padding-inline: 8px;
      }
    }

    @media (max-width: 640px) {
      .header-inner {
        flex-direction: column;
        align-items: flex-start;
      }

      .hero {
        padding-top: 48px;
      }

      .hero-actions {
        flex-direction: column;
        align-items: flex-start;
      }

      .hero-stats {
        gap: 10px;
      }

      .stat {
        padding: 8px 10px;
      }
    }

    CSS

    chmod -R 755 /var/www/html
    EOF

  tags = {
    Name = "http_server"
  }

  depends_on = [ local_file.aws_private_key_pem ]
}