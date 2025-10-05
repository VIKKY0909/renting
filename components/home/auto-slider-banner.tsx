"use client"

import { useState, useEffect } from "react"
import { ChevronLeft, ChevronRight } from "lucide-react"
import { Button } from "@/components/ui/button"
import Link from "next/link"

interface BannerSlide {
  id: string
  title: string
  subtitle?: string
  description?: string
  image_url: string
  button_text?: string
  button_link?: string
  gradient_from: string
  gradient_to: string
  gradient_via: string
  is_active: boolean
  sort_order: number
}

export function AutoSliderBanner() {
  const [bannerSlides, setBannerSlides] = useState<BannerSlide[]>([])
  const [currentSlide, setCurrentSlide] = useState(0)
  const [isAutoPlaying, setIsAutoPlaying] = useState(true)
  const [loading, setLoading] = useState(true)

  // Fetch banners from API
  useEffect(() => {
    const fetchBanners = async () => {
      try {
        const response = await fetch('/api/banners?category=Homepage Hero')
        const data = await response.json()
        if (response.ok && data.banners) {
          setBannerSlides(data.banners)
        } else {
          // Fallback to default banners if API fails
          setBannerSlides([
            {
              id: '1',
              title: 'New Collection',
              subtitle: 'Designer Dresses',
              description: 'Discover our latest collection of stunning designer dresses for every occasion',
              image_url: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=1200&h=600&fit=crop',
              button_text: 'Shop Now',
              button_link: '/browse',
              gradient_from: '#ff6b9d',
              gradient_to: '#c44569',
              gradient_via: '#f8b500',
              is_active: true,
              sort_order: 1
            },
            {
              id: '2',
              title: 'Summer Sale',
              subtitle: 'Up to 50% Off',
              description: 'Get ready for summer with our exclusive collection at unbeatable prices',
              image_url: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=1200&h=600&fit=crop',
              button_text: 'View Sale',
              button_link: '/browse?sale=true',
              gradient_from: '#c44569',
              gradient_to: '#f8b500',
              gradient_via: '#ff6b9d',
              is_active: true,
              sort_order: 2
            },
            {
              id: '3',
              title: 'Bridal Collection',
              subtitle: 'Dream Wedding',
              description: 'Make your special day unforgettable with our exquisite bridal collection',
              image_url: 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=1200&h=600&fit=crop',
              button_text: 'Explore',
              button_link: '/browse?category=bridal',
              gradient_from: '#f8b500',
              gradient_to: '#ff6b9d',
              gradient_via: '#c44569',
              is_active: true,
              sort_order: 3
            }
          ])
        }
      } catch (error) {
        console.error('Error fetching banners:', error)
        // Fallback to default banners if API fails
        setBannerSlides([
          {
            id: '1',
            title: 'New Collection',
            subtitle: 'Designer Dresses',
            description: 'Discover our latest collection of stunning designer dresses for every occasion',
            image_url: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=1200&h=600&fit=crop',
            button_text: 'Shop Now',
            button_link: '/browse',
            gradient_from: '#ff6b9d',
            gradient_to: '#c44569',
            gradient_via: '#f8b500',
            is_active: true,
            sort_order: 1
          },
          {
            id: '2',
            title: 'Summer Sale',
            subtitle: 'Up to 50% Off',
            description: 'Get ready for summer with our exclusive collection at unbeatable prices',
            image_url: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=1200&h=600&fit=crop',
            button_text: 'View Sale',
            button_link: '/browse?sale=true',
            gradient_from: '#c44569',
            gradient_to: '#f8b500',
            gradient_via: '#ff6b9d',
            is_active: true,
            sort_order: 2
          },
          {
            id: '3',
            title: 'Bridal Collection',
            subtitle: 'Dream Wedding',
            description: 'Make your special day unforgettable with our exquisite bridal collection',
            image_url: 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=1200&h=600&fit=crop',
            button_text: 'Explore',
            button_link: '/browse?category=bridal',
            gradient_from: '#f8b500',
            gradient_to: '#ff6b9d',
            gradient_via: '#c44569',
            is_active: true,
            sort_order: 3
          }
        ])
      } finally {
        setLoading(false)
      }
    }

    fetchBanners()
  }, [])

  // Auto-slide functionality
  useEffect(() => {
    if (!isAutoPlaying || bannerSlides.length === 0) return

    const interval = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % bannerSlides.length)
    }, 5000) // Change slide every 5 seconds

    return () => clearInterval(interval)
  }, [isAutoPlaying, bannerSlides.length])

  const nextSlide = () => {
    if (bannerSlides.length === 0) return
    setCurrentSlide((prev) => (prev + 1) % bannerSlides.length)
    setIsAutoPlaying(false)
  }

  const prevSlide = () => {
    if (bannerSlides.length === 0) return
    setCurrentSlide((prev) => (prev - 1 + bannerSlides.length) % bannerSlides.length)
    setIsAutoPlaying(false)
  }

  const goToSlide = (index: number) => {
    setCurrentSlide(index)
    setIsAutoPlaying(false)
  }

  // Don't render if loading or no banners
  if (loading) {
    return (
      <section className="relative h-[500px] md:h-[600px] overflow-hidden bg-gradient-to-br from-background to-muted/20 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </section>
    )
  }

  if (bannerSlides.length === 0) {
    return null
  }

  return (
    <section className="relative h-[500px] md:h-[600px] overflow-hidden bg-gradient-to-br from-background to-muted/20">
      {/* Slides Container */}
      <div className="relative h-full">
        {bannerSlides.map((slide, index) => (
          <div
            key={slide.id}
            className={`absolute inset-0 transition-all duration-1000 ease-in-out ${
              index === currentSlide ? 'opacity-100 translate-x-0' : 
              index < currentSlide ? 'opacity-0 -translate-x-full' : 
              'opacity-0 translate-x-full'
            }`}
          >
            {/* Background Image */}
            <div 
              className="absolute inset-0 bg-cover bg-center bg-no-repeat"
              style={{
                backgroundImage: `url(${slide.image_url})`,
                filter: 'brightness(0.7)'
              }}
            />
            
            {/* Dynamic Gradient Overlay */}
            <div 
              className="absolute inset-0"
              style={{
                background: `linear-gradient(135deg, ${slide.gradient_from}20, ${slide.gradient_via}20, ${slide.gradient_to}20)`
              }}
            />
            
            {/* Content */}
            <div className="relative h-full flex items-center">
              <div className="container mx-auto px-4">
                <div className="max-w-2xl">
                  <div className="animate-fade-in-up">
                    <h1 className="font-serif text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-4">
                      {slide.title}
                    </h1>
                    {slide.subtitle && (
                      <h2 className="font-serif text-3xl md:text-4xl lg:text-5xl font-semibold text-white/90 mb-6 gradient-text">
                        {slide.subtitle}
                      </h2>
                    )}
                    {slide.description && (
                      <p className="text-lg md:text-xl text-white/80 mb-8 max-w-lg leading-relaxed">
                        {slide.description}
                      </p>
                    )}
                    {slide.button_text && slide.button_link && (
                      <Link href={slide.button_link}>
                        <Button 
                          size="lg" 
                          className="btn-luxury text-lg px-8 py-6 animate-scale-in-spring"
                        >
                          {slide.button_text}
                        </Button>
                      </Link>
                    )}
                  </div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Navigation Arrows */}
      <Button
        variant="ghost"
        size="icon"
        className="absolute left-4 top-1/2 -translate-y-1/2 bg-white/20 hover:bg-white/30 text-white backdrop-blur-sm transition-all duration-300 hover:scale-110"
        onClick={prevSlide}
      >
        <ChevronLeft className="h-6 w-6" />
      </Button>
      
      <Button
        variant="ghost"
        size="icon"
        className="absolute right-4 top-1/2 -translate-y-1/2 bg-white/20 hover:bg-white/30 text-white backdrop-blur-sm transition-all duration-300 hover:scale-110"
        onClick={nextSlide}
      >
        <ChevronRight className="h-6 w-6" />
      </Button>

      {/* Dots Indicator */}
      <div className="absolute bottom-6 left-1/2 -translate-x-1/2 flex space-x-2">
        {bannerSlides.map((_, index) => (
          <button
            key={index}
            className={`w-3 h-3 rounded-full transition-all duration-300 ${
              index === currentSlide 
                ? 'bg-white scale-125' 
                : 'bg-white/50 hover:bg-white/70'
            }`}
            onClick={() => goToSlide(index)}
          />
        ))}
      </div>

      {/* Auto-play Toggle */}
      <Button
        variant="ghost"
        size="sm"
        className="absolute top-4 right-4 bg-white/20 hover:bg-white/30 text-white backdrop-blur-sm"
        onClick={() => setIsAutoPlaying(!isAutoPlaying)}
      >
        {isAutoPlaying ? '⏸️' : '▶️'}
      </Button>
    </section>
  )
}
