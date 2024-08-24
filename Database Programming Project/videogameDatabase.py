from flask import Flask, request, redirect, flash, render_template, session
import cx_Oracle

my_app = Flask(__name__)
my_app.secret_key = 'your_secret_key'

def get_db_connection():
    dsn = cx_Oracle.makedsn("acadoradbprd01.dpu.depaul.edu", 1521, sid="ACADPRD0")
    connection = cx_Oracle.connect(user='jwhitma2', password='cdm2070236', dsn=dsn)
    return connection

@my_app.route('/')
def index():
    return render_template('videogameDatabase.html')

@my_app.route('/submit', methods=['POST'])
def submit():
    print("Form submitted!")
    connection = None
    cursor = None
    player_id_value = None
    try:
        form_type = request.form.get('form_type')

        connection = get_db_connection()
        cursor = connection.cursor()

        if form_type == 'signup':
            # Handle signup form
            fname = request.form['fname']
            lname = request.form['lname']
            email = request.form['email']
            password = request.form['password']
            gamertag = request.form['gamertag']

            # Call procedure to insert new player
            player_id = cursor.var(cx_Oracle.STRING)
            cursor.callproc('newPlayer', [fname, lname, email, password, gamertag, player_id])
            
            player_id_value = player_id.getvalue()
            print(f"Generated Player ID: {player_id_value}")
            
            if player_id_value is None:
                raise ValueError("Player ID is None after newPlayer procedure.")

            # Start session for the new player
            cursor.callproc('start_or_update_session', [player_id_value, 'login'])
            session['player_id'] = player_id_value  # Store player_id in session
            flash('Signup successful!')
            return redirect('/game_session')

        elif form_type == 'login':
            # Handle login form
            email = request.form['login_email']
            password = request.form['login_password']

            # Call procedure to authenticate user
            player_id = cursor.var(cx_Oracle.STRING)
            cursor.callproc('authenticate_user', [email, password, player_id])
            
            player_id_value = player_id.getvalue()
            print(f"Retrieved Player ID: {player_id_value}")
            
            if player_id_value is None:
                raise ValueError("Invalid email or password.")

            # Start or update session after successful login
            cursor.callproc('start_or_update_session', [player_id_value, 'login'])
            session['player_id'] = player_id_value  # Store player_id in session
            flash('Login successful!')
            return redirect('/game_session')

        else:
            flash('Error: Invalid form type')

        connection.commit()

    except cx_Oracle.DatabaseError as e:
        error, = e.args
        print("Oracle Error:", error.message)
        flash(f"Error: {error.message}")

    except ValueError as ve:
        print("Value Error:", str(ve))
        flash(f"Error: {str(ve)}")

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
    
    return redirect('/')

@my_app.route('/game_session')
def game_session():
    if 'player_id' not in session:
        flash('Please log in first.')
        return redirect('/')

    return render_template('game_session.html')

@my_app.route('/logout', methods=['POST'])
def logout():
    player_id = session.get('player_id')

    if player_id:
        connection = None
        cursor = None
        try:
            connection = get_db_connection()
            cursor = connection.cursor()
            
            # Call procedure to update session (logout)
            cursor.callproc('start_or_update_session', [player_id, 'logout'])
            connection.commit()
            flash('Logged out successfully!')

        except cx_Oracle.DatabaseError as e:
            error, = e.args
            print("Oracle Error:", error.message)
            flash(f"Error: {error.message}")

        finally:
            if cursor:
                cursor.close()
            if connection:
                connection.close()

        # Clear the session to log out the user
        session.pop('player_id', None)

    return redirect('/')

if __name__ == '__main__':
    my_app.run(debug=True)
