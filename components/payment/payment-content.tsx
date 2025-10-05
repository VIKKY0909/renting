"use client"

import type React from "react"

import { motion } from "framer-motion"
import { CreditCard, Wallet, Building2, Shield, ArrowLeft, Check } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Label } from "@/components/ui/label"
import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { useCart } from "@/lib/cart-context"
import { createMultiItemOrder } from "@/lib/actions/orders"

export default function PaymentContent() {
  const router = useRouter()
  const { items, getTotalPrice, getTotalDeposit, getGrandTotal, clearCart } = useCart()
  const [paymentMethod, setPaymentMethod] = useState("card")
  const [processing, setProcessing] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Redirect if cart is empty
  useEffect(() => {
    if (items.length === 0 && !success) {
      router.push("/cart")
    }
  }, [items, success, router])

  const orderSummary = {
    items: items.map(item => ({
      name: item.title,
      size: item.selectedSize || "M",
      rentalDays: item.rentalDays,
      price: item.rentalPrice,
    })),
    subtotal: getTotalPrice(),
    discount: 0,
    securityDeposit: getTotalDeposit(),
    deliveryCharge: 0,
    total: getGrandTotal(),
  }

  const handlePayment = async (e: React.FormEvent) => {
    e.preventDefault()
    setProcessing(true)
    setError(null)

    try {
      // Create form data for order
      const formData = new FormData()
      formData.append("items", JSON.stringify(items))
      formData.append("payment_method", paymentMethod)
      formData.append("total_amount", getGrandTotal().toString())

      // Simulate payment processing delay
      await new Promise(resolve => setTimeout(resolve, 2000))

      // Create order
          const { success: orderSuccess, error: orderError } = await createMultiItemOrder(formData)
      
      if (orderSuccess) {
        setSuccess(true)
        clearCart()
        // Redirect to profile page after 3 seconds
        setTimeout(() => {
          router.push("/profile")
        }, 3000)
      } else {
        setError(orderError || "Payment failed. Please try again.")
      }
    } catch (error) {
      console.error("Payment error:", error)
      setError("Payment failed. Please try again.")
    } finally {
      setProcessing(false)
    }
  }

  if (success) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-background to-secondary/20 flex items-center justify-center px-4">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.5 }}
          className="bg-card p-12 rounded-2xl border border-border shadow-lg text-center max-w-md"
        >
          <div className="w-20 h-20 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center mx-auto mb-6">
            <Check className="w-10 h-10 text-white" />
          </div>
          <h2 className="font-serif text-3xl mb-4">Payment Successful!</h2>
          <p className="text-muted-foreground mb-6">
            Your order has been confirmed. We'll send you tracking details via email.
          </p>
          <p className="text-sm text-muted-foreground">Redirecting to your orders...</p>
        </motion.div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-secondary/20 py-12 px-4">
      <div className="container mx-auto max-w-6xl">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="mb-8"
        >
          <Button variant="ghost" onClick={() => router.back()} className="mb-4">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Cart
          </Button>
          <h1 className="font-serif text-4xl md:text-5xl text-balance mb-2">Complete Your Payment</h1>
          <p className="text-muted-foreground">Secure checkout powered by industry-leading payment providers</p>
        </motion.div>

        <div className="grid lg:grid-cols-3 gap-8">
          {/* Payment Form */}
          <div className="lg:col-span-2">
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6 }}
              className="bg-card p-8 rounded-2xl border border-border"
            >
              <h2 className="font-serif text-2xl mb-6">Payment Method</h2>

              <form onSubmit={handlePayment} className="space-y-6">
                <RadioGroup value={paymentMethod} onValueChange={setPaymentMethod}>
                  <div className="space-y-4">
                    {/* Card Payment */}
                    <div className="flex items-center space-x-3 p-4 rounded-xl border-2 border-border hover:border-primary/50 transition-colors cursor-pointer">
                      <RadioGroupItem value="card" id="card" />
                      <Label htmlFor="card" className="flex items-center gap-3 cursor-pointer flex-1">
                        <CreditCard className="w-5 h-5 text-primary" />
                        <span className="font-medium">Credit / Debit Card</span>
                      </Label>
                    </div>

                    {/* UPI */}
                    <div className="flex items-center space-x-3 p-4 rounded-xl border-2 border-border hover:border-primary/50 transition-colors cursor-pointer">
                      <RadioGroupItem value="upi" id="upi" />
                      <Label htmlFor="upi" className="flex items-center gap-3 cursor-pointer flex-1">
                        <Wallet className="w-5 h-5 text-primary" />
                        <span className="font-medium">UPI</span>
                      </Label>
                    </div>

                    {/* Net Banking */}
                    <div className="flex items-center space-x-3 p-4 rounded-xl border-2 border-border hover:border-primary/50 transition-colors cursor-pointer">
                      <RadioGroupItem value="netbanking" id="netbanking" />
                      <Label htmlFor="netbanking" className="flex items-center gap-3 cursor-pointer flex-1">
                        <Building2 className="w-5 h-5 text-primary" />
                        <span className="font-medium">Net Banking</span>
                      </Label>
                    </div>
                  </div>
                </RadioGroup>

                {/* Card Details Form */}
                {paymentMethod === "card" && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: "auto" }}
                    exit={{ opacity: 0, height: 0 }}
                    className="space-y-4 pt-4"
                  >
                    <div>
                      <Label>Card Number</Label>
                      <Input type="text" placeholder="1234 5678 9012 3456" maxLength={19} required />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <Label>Expiry Date</Label>
                        <Input type="text" placeholder="MM/YY" maxLength={5} required />
                      </div>
                      <div>
                        <Label>CVV</Label>
                        <Input type="text" placeholder="123" maxLength={3} required />
                      </div>
                    </div>
                    <div>
                      <Label>Cardholder Name</Label>
                      <Input type="text" placeholder="Name on card" required />
                    </div>
                  </motion.div>
                )}

                {/* UPI Form */}
                {paymentMethod === "upi" && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: "auto" }}
                    exit={{ opacity: 0, height: 0 }}
                    className="space-y-4 pt-4"
                  >
                    <div>
                      <Label>UPI ID</Label>
                      <Input type="text" placeholder="yourname@upi" required />
                    </div>
                  </motion.div>
                )}

                {/* Net Banking Form */}
                {paymentMethod === "netbanking" && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: "auto" }}
                    exit={{ opacity: 0, height: 0 }}
                    className="space-y-4 pt-4"
                  >
                    <div>
                      <Label>Select Bank</Label>
                      <select className="w-full p-3 rounded-lg border border-border bg-background">
                        <option>State Bank of India</option>
                        <option>HDFC Bank</option>
                        <option>ICICI Bank</option>
                        <option>Axis Bank</option>
                        <option>Kotak Mahindra Bank</option>
                      </select>
                    </div>
                  </motion.div>
                )}

                {/* Error Message */}
                {error && (
                  <div className="p-4 bg-destructive/10 border border-destructive/20 rounded-xl">
                    <p className="text-destructive text-sm">{error}</p>
                  </div>
                )}

                {/* Security Notice */}
                <div className="flex items-start gap-3 p-4 bg-secondary/50 rounded-xl">
                  <Shield className="w-5 h-5 text-primary flex-shrink-0 mt-0.5" />
                  <div className="text-sm text-muted-foreground">
                    <p className="font-medium text-foreground mb-1">Secure Payment</p>
                    <p>Your payment information is encrypted and secure. We never store your complete card details.</p>
                  </div>
                </div>

                {/* Submit Button */}
                <Button
                  type="submit"
                  disabled={processing}
                  className="w-full py-6 text-lg bg-gradient-to-r from-primary to-accent hover:shadow-lg transition-all duration-300"
                >
                  {processing ? (
                    <>
                      <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin mr-2" />
                      Processing...
                    </>
                  ) : (
                    `Pay ₹${orderSummary.total.toLocaleString("en-IN")}`
                  )}
                </Button>
              </form>
            </motion.div>
          </div>

          {/* Order Summary */}
          <div className="lg:col-span-1">
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6 }}
              className="bg-card p-6 rounded-2xl border border-border sticky top-4"
            >
              <h2 className="font-serif text-2xl mb-6">Order Summary</h2>

              <div className="space-y-4 mb-6">
                {orderSummary.items.map((item, index) => (
                  <div key={index} className="pb-4 border-b border-border">
                    <h3 className="font-medium mb-1">{item.name}</h3>
                    <p className="text-sm text-muted-foreground">
                      Size: {item.size} • {item.rentalDays} days
                    </p>
                    <p className="text-sm font-medium mt-2">₹{item.price.toLocaleString("en-IN")}</p>
                  </div>
                ))}
              </div>

              <div className="space-y-3 mb-6">
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Subtotal</span>
                  <span>₹{orderSummary.subtotal.toLocaleString("en-IN")}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Discount</span>
                  <span className="text-green-600">-₹{orderSummary.discount.toLocaleString("en-IN")}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Security Deposit</span>
                  <span>₹{orderSummary.securityDeposit.toLocaleString("en-IN")}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Delivery</span>
                  <span className="text-green-600">FREE</span>
                </div>
              </div>

              <div className="pt-4 border-t border-border">
                <div className="flex justify-between items-center mb-2">
                  <span className="font-serif text-xl">Total</span>
                  <span className="font-serif text-2xl">₹{orderSummary.total.toLocaleString("en-IN")}</span>
                </div>
                <p className="text-xs text-muted-foreground">Security deposit will be refunded after return</p>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  )
}
