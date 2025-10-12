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
  mobile_image_url?: string
  link_text?: string
  link_url?: string
  category_id?: string
  display_order: number
  is_active: boolean
  created_at: string
  updated_at: string
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
              link_text: 'Shop Now',
              link_url: '/browse',
              is_active: true,
              display_order: 1,
              created_at: '',
              updated_at: ''
            },
            {
              id: '2',
              title: 'Summer Sale',
              subtitle: 'Up to 50% Off',
              description: 'Get ready for summer with our exclusive collection at unbeatable prices',
              image_url: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=1200&h=600&fit=crop',
              link_text: 'View Sale',
              link_url: '/browse?sale=true',
              is_active: true,
              display_order: 2,
              created_at: '',
              updated_at: ''
            },
            {
              id: '3',
              title: 'Bridal Collection',
              subtitle: 'Dream Wedding',
              description: 'Make your special day unforgettable with our exquisite bridal collection',
              image_url: 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=1200&h=600&fit=crop',
              link_text: 'Explore',
              link_url: '/browse?category=bridal',
              is_active: true,
              display_order: 3,
              created_at: '',
              updated_at: ''
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
            link_text: 'Shop Now',
            link_url: '/browse',
            is_active: true,
            display_order: 1,
            created_at: '',
            updated_at: ''
          },
          {
            id: '2',
            title: 'Summer Sale',
            subtitle: 'Up to 50% Off',
            description: 'Get ready for summer with our exclusive collection at unbeatable prices',
            image_url: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=1200&h=600&fit=crop',
            link_text: 'View Sale',
            link_url: '/browse?sale=true',
            is_active: true,
            display_order: 2,
            created_at: '',
            updated_at: ''
          },
          {
            id: '3',
            title: 'Bridal Collection',
            subtitle: 'Dream Wedding',
            description: 'Make your special day unforgettable with our exquisite bridal collection',
            image_url: 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=1200&h=600&fit=crop',
            link_text: 'Explore',
            link_url: '/browse?category=bridal',
            is_active: true,
            display_order: 3,
            created_at: '',
            updated_at: ''
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
            
            {/* Dark Gradient Overlay */}
            <div 
              className="absolute inset-0 bg-gradient-to-r from-black/60 via-black/40 to-transparent"
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
                    {slide.link_url && (
                      <Link href={slide.link_url}>
                        <Button 
                          size="lg" 
                          className="btn-luxury text-lg px-10 py-7 animate-scale-in-spring hover-glow shadow-2xl font-semibold"
                        >
                          {slide.link_text || 'Shop Now'}
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
            aria-label={`Go to slide ${index + 1}`}
          />
        ))}
      </div>
    </section>
  )
}
