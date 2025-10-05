"use client"

import { motion } from "framer-motion"
import { Sparkles, Heart, Shield, Users } from "lucide-react"
import Image from "next/image"

export default function AboutContent() {
  const values = [
    {
      icon: Sparkles,
      title: "Quality First",
      description: "Every outfit is professionally dry-cleaned and quality-checked before delivery",
    },
    {
      icon: Heart,
      title: "Sustainable Fashion",
      description: "Reduce fashion waste by sharing designer outfits within our community",
    },
    {
      icon: Shield,
      title: "Trust & Safety",
      description: "Secure payments, verified users, and comprehensive insurance on all rentals",
    },
    {
      icon: Users,
      title: "Community Driven",
      description: "Connect with fashion lovers across India and share your designer wardrobe",
    },
  ]

  const team = [
    {
      name: "Priya Sharma",
      role: "Founder & CEO",
      image: "/professional-indian-woman-ceo.jpg",
    },
    {
      name: "Rahul Verma",
      role: "Head of Operations",
      image: "/professional-indian-man-operations.jpg",
    },
    {
      name: "Ananya Patel",
      role: "Fashion Curator",
      image: "/professional-indian-woman-fashion.jpg",
    },
  ]

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-secondary/20">
      {/* Hero Section */}
      <section className="relative py-20 px-4 overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-r from-primary/10 via-accent/10 to-secondary/10" />
        <div className="container mx-auto max-w-6xl relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            <h1 className="font-serif text-5xl md:text-6xl lg:text-7xl text-balance mb-6 bg-gradient-to-r from-primary via-accent to-secondary bg-clip-text text-transparent">
              About Rentimade
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground max-w-3xl mx-auto text-balance leading-relaxed">
              Redefining fashion accessibility in India, one outfit at a time
            </p>
          </motion.div>
        </div>
      </section>

      {/* Story Section */}
      <section className="py-16 px-4">
        <div className="container mx-auto max-w-6xl">
          <div className="grid md:grid-cols-2 gap-12 items-center">
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
            >
              <h2 className="font-serif text-4xl md:text-5xl mb-6 text-balance">Our Story</h2>
              <div className="space-y-4 text-lg leading-relaxed text-muted-foreground">
                <p>
                  Rentimade was born from a simple observation: beautiful designer outfits sitting unused in wardrobes
                  while others searched for the perfect outfit for their special occasions.
                </p>
                <p>
                  We created a platform that connects fashion lovers across India, making designer wear accessible and
                  sustainable. Whether you're attending a wedding, a festive celebration, or a special event, Rentimade
                  brings premium fashion within reach.
                </p>
                <p>
                  Today, we're proud to serve thousands of customers and lenders, building a community that believes in
                  sharing, sustainability, and celebrating every special moment in style.
                </p>
              </div>
            </motion.div>
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="relative h-[500px] rounded-2xl overflow-hidden"
            >
              <Image src="/indian-fashion-designer-clothes-wardrobe.jpg" alt="Our Story" fill className="object-cover" />
            </motion.div>
          </div>
        </div>
      </section>

      {/* Values Section */}
      <section className="py-16 px-4 bg-secondary/30">
        <div className="container mx-auto max-w-6xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-12"
          >
            <h2 className="font-serif text-4xl md:text-5xl mb-4 text-balance">Our Values</h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto text-balance">
              The principles that guide everything we do
            </p>
          </motion.div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            {values.map((value, index) => (
              <motion.div
                key={value.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                className="bg-card p-6 rounded-xl border border-border hover:border-primary/50 transition-all duration-300 hover:shadow-lg"
              >
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center mb-4">
                  <value.icon className="w-6 h-6 text-white" />
                </div>
                <h3 className="font-serif text-xl mb-2">{value.title}</h3>
                <p className="text-muted-foreground leading-relaxed">{value.description}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Team Section */}
      <section className="py-16 px-4">
        <div className="container mx-auto max-w-6xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-12"
          >
            <h2 className="font-serif text-4xl md:text-5xl mb-4 text-balance">Meet Our Team</h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto text-balance">
              Passionate individuals working to transform fashion rental in India
            </p>
          </motion.div>

          <div className="grid md:grid-cols-3 gap-8">
            {team.map((member, index) => (
              <motion.div
                key={member.name}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                className="group"
              >
                <div className="relative h-80 rounded-xl overflow-hidden mb-4">
                  <Image
                    src={member.image || "/placeholder.svg"}
                    alt={member.name}
                    fill
                    className="object-cover group-hover:scale-105 transition-transform duration-500"
                  />
                </div>
                <h3 className="font-serif text-2xl mb-1">{member.name}</h3>
                <p className="text-muted-foreground">{member.role}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-16 px-4 bg-gradient-to-r from-primary/10 via-accent/10 to-secondary/10">
        <div className="container mx-auto max-w-4xl text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
          >
            <h2 className="font-serif text-4xl md:text-5xl mb-6 text-balance">Join Our Fashion Community</h2>
            <p className="text-xl text-muted-foreground mb-8 text-balance">
              Whether you want to rent designer outfits or share your wardrobe, we're here to make fashion accessible
              for everyone.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <a
                href="/browse"
                className="px-8 py-4 bg-gradient-to-r from-primary to-accent text-white rounded-full font-medium hover:shadow-lg transition-all duration-300 hover:scale-105"
              >
                Start Renting
              </a>
              <a
                href="/lend"
                className="px-8 py-4 bg-card border-2 border-primary rounded-full font-medium hover:bg-primary/10 transition-all duration-300"
              >
                Become a Lender
              </a>
            </div>
          </motion.div>
        </div>
      </section>
    </div>
  )
}
