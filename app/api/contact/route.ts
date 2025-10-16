import { NextRequest, NextResponse } from "next/server"
import { Resend } from "resend"

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { name, email, phone, subject, message } = body

    // Validate required fields
    if (!name || !email || !subject || !message) {
      return NextResponse.json(
        { error: "Missing required fields" },
        { status: 400 }
      )
    }

    // Email content
    const emailContent = `
New Contact Form Submission from Rentimade

Name: ${name}
Email: ${email}
Phone: ${phone || 'Not provided'}
Subject: ${subject}

Message:
${message}

---
Submitted on: ${new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}
    `.trim()

    // Send email via Resend
    const resendApiKey = process.env.RESEND_API_KEY
    if (!resendApiKey) {
      console.warn("Missing RESEND_API_KEY, skipping email send. Logging only.")
      console.log("Contact form submission:", {
        name,
        email,
        phone,
        subject,
        message,
        timestamp: new Date().toISOString(),
      })
    } else {
      const resend = new Resend(resendApiKey)
      await resend.emails.send({
        from: "Rentimade <no-reply@rentimade.dev>",
        to: ["contactrentimade@gmail.com"],
        replyTo: email,
        subject: `Contact Form: ${subject}`,
        text: emailContent,
      })
    }

    return NextResponse.json(
      { 
        success: true, 
        message: "Thank you for your message! We'll get back to you within 24 hours." 
      },
      { status: 200 }
    )

  } catch (error) {
    console.error("Contact form error:", error)
    return NextResponse.json(
      { error: "Failed to send message. Please try again." },
      { status: 500 }
    )
  }
}

