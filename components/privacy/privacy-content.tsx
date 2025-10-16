"use client"

import { motion } from "framer-motion"
import { Shield, Lock, Eye, UserCheck, FileText, AlertCircle } from "lucide-react"

export default function PrivacyContent() {
  const sections = [
    {
      icon: FileText,
      title: "Information We Collect",
      content: [
        "Personal information (name, email, phone number, address)",
        "Payment and banking information for transactions",
        "Profile information and preferences",
        "Rental history and transaction details",
        "Device information and usage data",
        "Photos and descriptions of outfits you list",
      ],
    },
    {
      icon: Eye,
      title: "How We Use Your Information",
      content: [
        "Process rentals and facilitate transactions",
        "Communicate about orders, deliveries, and returns",
        "Improve our platform and user experience",
        "Prevent fraud and ensure platform security",
        "Send promotional offers (with your consent)",
        "Comply with legal obligations",
      ],
    },
    {
      icon: Lock,
      title: "Data Security",
      content: [
        "Industry-standard encryption for all data transmission",
        "Secure payment processing through certified gateways",
        "Regular security audits and updates",
        "Restricted access to personal information",
        "Secure data storage with backup systems",
        "Compliance with Indian data protection laws",
      ],
    },
    {
      icon: UserCheck,
      title: "Your Rights",
      content: [
        "Access your personal data anytime",
        "Request correction of inaccurate information",
        "Delete your account and associated data",
        "Opt-out of marketing communications",
        "Export your data in a portable format",
        "Lodge complaints with data protection authorities",
      ],
    },
    {
      icon: Shield,
      title: "Data Sharing",
      content: [
        "We never sell your personal information",
        "Share with service providers (delivery, payments) as needed",
        "Disclose to law enforcement when legally required",
        "Share aggregated, anonymized data for analytics",
        "Obtain consent before sharing with third parties",
        "Protect your data with strict confidentiality agreements",
      ],
    },
    {
      icon: AlertCircle,
      title: "Cookies and Tracking",
      content: [
        "Use cookies to enhance user experience",
        "Track usage patterns to improve our platform",
        "Remember your preferences and settings",
        "Analyze traffic and user behavior",
        "You can control cookies through browser settings",
        "Essential cookies are required for platform functionality",
      ],
    },
  ]

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-secondary/20">
      {/* Hero Section */}
      <section className="relative py-20 px-4 overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-r from-primary/10 via-accent/10 to-secondary/10" />
        <div className="container mx-auto max-w-4xl relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            <h1 className="font-serif text-5xl md:text-6xl lg:text-7xl text-balance mb-6 bg-gradient-to-r from-primary via-accent to-secondary bg-clip-text text-transparent">
              Privacy Policy
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground max-w-3xl mx-auto text-balance leading-relaxed">
              Your privacy and data security are our top priorities
            </p>
            <p className="text-sm text-muted-foreground mt-4">Last updated: February 10, 2025</p>
          </motion.div>
        </div>
      </section>

      {/* Introduction */}
      <section className="py-16 px-4">
        <div className="container mx-auto max-w-4xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="bg-card p-8 rounded-2xl border border-border mb-12"
          >
            <p className="text-lg leading-relaxed text-muted-foreground">
              At Rentimade, we are committed to protecting your privacy and ensuring the security of your personal
              information. This Privacy Policy explains how we collect, use, store, and protect your data when you use
              our platform. By using Rentimade, you agree to the practices described in this policy.
            </p>
          </motion.div>

          {/* Policy Sections */}
          <div className="space-y-8">
            {sections.map((section, index) => (
              <motion.div
                key={section.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                className="bg-card p-8 rounded-2xl border border-border hover:border-primary/50 transition-colors"
              >
                <div className="flex items-start gap-4 mb-6">
                  <div className="w-12 h-12 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center flex-shrink-0">
                    <section.icon className="w-6 h-6 text-white" />
                  </div>
                  <div>
                    <h2 className="font-serif text-2xl md:text-3xl mb-4">{section.title}</h2>
                    <ul className="space-y-3">
                      {section.content.map((item, i) => (
                        <li key={i} className="flex items-start gap-3">
                          <span className="w-1.5 h-1.5 rounded-full bg-primary mt-2 flex-shrink-0" />
                          <span className="text-muted-foreground leading-relaxed">{item}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          {/* Additional Information */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="mt-12 space-y-8"
          >
            <div className="bg-card p-8 rounded-2xl border border-border">
              <h2 className="font-serif text-2xl md:text-3xl mb-4">Data Retention</h2>
              <p className="text-muted-foreground leading-relaxed">
                We retain your personal information for as long as necessary to provide our services and comply with
                legal obligations. When you delete your account, we remove your personal data within 30 days, except for
                information we're required to retain for legal, tax, or regulatory purposes.
              </p>
            </div>

            <div className="bg-card p-8 rounded-2xl border border-border">
              <h2 className="font-serif text-2xl md:text-3xl mb-4">Children's Privacy</h2>
              <p className="text-muted-foreground leading-relaxed">
                Rentimade is not intended for users under 18 years of age. We do not knowingly collect personal
                information from children. If you believe we have collected information from a child, please contact us
                immediately.
              </p>
            </div>

            <div className="bg-card p-8 rounded-2xl border border-border">
              <h2 className="font-serif text-2xl md:text-3xl mb-4">Policy Updates</h2>
              <p className="text-muted-foreground leading-relaxed">
                We may update this Privacy Policy periodically to reflect changes in our practices or legal
                requirements. We'll notify you of significant changes via email or platform notification. Your continued
                use of Rentimade after updates constitutes acceptance of the revised policy.
              </p>
            </div>

            <div className="bg-card p-8 rounded-2xl border border-border">
              <h2 className="font-serif text-2xl md:text-3xl mb-4">Contact Us</h2>
              <p className="text-muted-foreground leading-relaxed mb-4">
                If you have questions about this Privacy Policy or how we handle your data, please contact us:
              </p>
              <div className="space-y-2 text-muted-foreground">
                <p>
                  <strong>Email:</strong>{" "}
                  <a href="mailto:contactrentimade@gmail.com" className="text-primary hover:underline">
                    contactrentimade@gmail.com
                  </a>
                </p>
                <p>
                  <strong>Phone:</strong>{" "}
                  <a href="tel:+919329862253" className="text-primary hover:underline">
                    +91 9329862253
                  </a>
                </p>
                <p>
                  <strong>Address:</strong>{" "}
                  <span className="text-muted-foreground">
                    Khargon, Madhya Pradesh, India
                  </span>
                </p>
              </div>
            </div>
          </motion.div>
        </div>
      </section>
    </div>
  )
}
