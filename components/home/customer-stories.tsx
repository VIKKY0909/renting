"use client"

import { useState } from "react"
import { ChevronLeft, ChevronRight, Star } from "lucide-react"
import { Button } from "@/components/ui/button"

const stories = [
  {
    name: "Priya Sharma",
    location: "Mumbai",
    image: "/indian-woman-in-designer-lehenga.jpg",
    story: "Rented a beautiful lehenga for my sister's wedding. The quality was amazing and I saved so much money!",
    rating: 5,
    outfit: "Designer Lehenga",
  },
  {
    name: "Ananya Patel",
    location: "Delhi",
    image: "/indian-woman-in-elegant-saree.jpg",
    story: "The saree I rented was absolutely stunning. Delivery was on time and the return process was hassle-free.",
    rating: 5,
    outfit: "Silk Saree",
  },
  {
    name: "Riya Desai",
    location: "Bangalore",
    image: "/indian-woman-in-designer-gown.jpg",
    story: "Perfect gown for my engagement party. Everyone asked where I got it from. Highly recommend Rentimade!",
    rating: 5,
    outfit: "Evening Gown",
  },
]

export function CustomerStories() {
  const [currentIndex, setCurrentIndex] = useState(0)

  const next = () => {
    setCurrentIndex((prev) => (prev + 1) % stories.length)
  }

  const prev = () => {
    setCurrentIndex((prev) => (prev - 1 + stories.length) % stories.length)
  }

  return (
    <section className="py-20 bg-muted/30">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <h2 className="font-serif text-4xl md:text-5xl font-bold mb-4">Customer Stories</h2>
          <p className="text-lg text-muted-foreground">Hear from our happy customers</p>
        </div>

        <div className="max-w-4xl mx-auto relative">
          <div className="bg-card rounded-3xl p-8 md:p-12 border border-border shadow-lg">
            <div className="grid md:grid-cols-2 gap-8 items-center">
              <div className="relative aspect-square rounded-2xl overflow-hidden">
                <img
                  src={stories[currentIndex].image || "/placeholder.svg"}
                  alt={stories[currentIndex].name}
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="space-y-4">
                <div className="flex gap-1">
                  {Array.from({ length: stories[currentIndex].rating }).map((_, i) => (
                    <Star key={i} className="h-5 w-5 fill-primary text-primary" />
                  ))}
                </div>
                <p className="text-lg leading-relaxed italic">"{stories[currentIndex].story}"</p>
                <div>
                  <p className="font-semibold text-lg">{stories[currentIndex].name}</p>
                  <p className="text-sm text-muted-foreground">{stories[currentIndex].location}</p>
                  <p className="text-sm text-primary mt-1">{stories[currentIndex].outfit}</p>
                </div>
              </div>
            </div>
          </div>

          <div className="flex items-center justify-center gap-4 mt-8">
            <Button variant="outline" size="icon" onClick={prev} className="rounded-full bg-transparent">
              <ChevronLeft className="h-5 w-5" />
            </Button>
            <div className="flex gap-2">
              {stories.map((_, index) => (
                <button
                  key={index}
                  onClick={() => setCurrentIndex(index)}
                  className={`h-2 rounded-full transition-all ${
                    index === currentIndex ? "w-8 bg-primary" : "w-2 bg-border"
                  }`}
                />
              ))}
            </div>
            <Button variant="outline" size="icon" onClick={next} className="rounded-full bg-transparent">
              <ChevronRight className="h-5 w-5" />
            </Button>
          </div>
        </div>
      </div>
    </section>
  )
}
