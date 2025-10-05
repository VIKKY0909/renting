import { Tag } from "lucide-react"

export function DiscountBanner() {
  return (
    <section className="bg-gradient-to-r from-secondary via-primary to-accent py-4">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-center gap-3 text-white">
          <Tag className="h-5 w-5" />
          <p className="text-sm md:text-base font-medium">
            Special Offer: Use code <span className="font-bold">FIRSTTIME2025</span> for 20% off your first rental
          </p>
        </div>
      </div>
    </section>
  )
}
