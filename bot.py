from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Merhaba! Ben bir Telegram botuyum.")

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Bana /start yazarsan merhaba derim!")

async def konum1(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Üsküdar için rota oluşturuluyor...")

async def konum2(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Kandilli için rota oluşturuluyor...")

app = ApplicationBuilder().token("8164744445:AAEFiHSZZyYY1QkAWnb9SK4sRGHbZuRBTSE").build()

app.add_handler(CommandHandler("start", start))
app.add_handler(CommandHandler("help", help_command))
app.add_handler(CommandHandler("uskudar", konum1))
app.add_handler(CommandHandler("kandilli", konum2))

app.run_polling()
