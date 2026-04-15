from tkinter import *
from tkinter import messagebox
import pyperclip
import json
# ---------------------------- PASSWORD GENERATOR ------------------------------- #
def generate_password():
    # Password Generator Project
    import random
    letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u',
               'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
               'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
    numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
    symbols = ['!', '#', '$', '%', '&', '(', ')', '*', '+']

    nr_letters = random.randint(8, 10)
    nr_symbols = random.randint(2, 4)
    nr_numbers = random.randint(2, 4)

    password_letters = [random.choice(letters) for _ in range(nr_letters)]
    password_symbol = [random.choice(symbols) for _ in range(nr_symbols)]
    password_numbers = [random.choice(numbers) for _ in range(nr_numbers)]

    password_list = password_letters + password_symbol + password_numbers
    random.shuffle(password_list)

    password = "".join(password_list)
    password_input.insert(0, password)
    pyperclip.copy(password)
# ---------------------------- SAVE PASSWORD ------------------------------- #
def save():
    website = website_input.get().capitalize()
    email = email_input.get()
    password = password_input.get()
    new_data = {
        website: {
            "email": email,
            "password": password
        }
    }
    if len(website) == 0 or len(email) == 0 or len(password) == 0:
        messagebox.showerror("Error", "Please fill all fields")
    else:
        try: #tries to read file, but if no file exists, it will create a new file
            with open("password.json", "r") as data_file:
                #Reading old data
                data = json.load(data_file)
        except FileNotFoundError: # if no file exists, this creates a new file
                with open("password.json", "w") as data_file:
                    json.dump(new_data, data_file, indent=4)
        else: # if the file does exist then it just updates existing file
            #Updating old data with new data
            data.update(new_data)
            with open("password.json", "w") as data_file:
                #Saving updated data
                json.dump(data, data_file, indent=4)
        finally: # once all above runs, we still want to clear passwords in consol
            website_input.delete(0, END)
            email_input.delete(0, END)
            password_input.delete(0, END)

# ---------------------------- FIND PASSWORD ------------------------------- #
def find_password():
    website = website_input.get().capitalize()
    try:
        with open("password.json") as data_file:
            data = json.load(data_file)
    except FileNotFoundError:
        messagebox.showinfo(title = "Error", message = "No data file exists")
    else:
        if website in data:
            email = data[website]["email"]
            password = data[website]["password"]
            messagebox.showinfo("Website", f"Email: {email}\nPassword: {password}")
        else:
            messagebox.showinfo(title="Error", message=f"No details for {website} exists")


# ---------------------------- UI SETUP ------------------------------- #
window = Tk()
window.title("Password Generator")
window.config(padx=50, pady=50, bg="#f0f0f0")   # nicer padding and background

# Logo
canvas = Canvas(width=200, height=200, bg="#f0f0f0", highlightthickness=0)
key_logo = PhotoImage(file="logo.png")
canvas.create_image(100, 100, image=key_logo)
canvas.grid(row=0, column=1, pady=20)

# Labels
website_label = Label(text="Website:", bg="#f0f0f0")
website_label.grid(row=1, column=0, sticky="e", padx=(0, 10))

email_label = Label(text="Email/Username:", bg="#f0f0f0")
email_label.grid(row=2, column=0, sticky="e", padx=(0, 10))

password_label = Label(text="Password:", bg="#f0f0f0")
password_label.grid(row=3, column=0, sticky="e", padx=(0, 10))

# Inputs
website_input = Entry(width=34)
website_input.grid(row=1, column=1, columnspan=2, sticky="w")
website_input.focus_set()

email_input = Entry(width=54)
email_input.grid(row=2, column=1, columnspan=2, sticky="w")

# Password row - aligned properly
password_input = Entry(width=34)          # shorter so button fits nicely
password_input.grid(row=3, column=1, sticky="w")

generate_button = Button(text="Generate Password", command=generate_password)
generate_button.grid(row=3, column=2, sticky="w", padx=(8, 0))

# Add button
add_button = Button(text="Add", width=36, command = save)
add_button.grid(row=4, column=1, columnspan=2, pady=(10, 0))

# Search button
search_button = Button(text="Search", width = 14, command = find_password)
search_button.grid(row=1, column=2, sticky="w", padx=(8, 0))


window.mainloop()
