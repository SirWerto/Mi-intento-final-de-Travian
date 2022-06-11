import sys

from message import read_message, write_answer
from medusa_model_1 import medusa_model_1
from medusa_model_n import medusa_model_n


def eval_message(message, model_1, model_n):

    ndays_n, ndays_1 = [], []
    [ndays_n.append(x["fe_struct"]) if x["fe_type"] == "ndays_n"
     else ndays_1.append(x["fe_struct"]) for x in message]

    pred1 = model_1.predict(ndays_1)
    predn = model_n.predict(ndays_n)

    return pred1 + predn


if __name__ == "__main__":
    try:
        model_1 = medusa_model_1(sys.argv[1])
        model_n = medusa_model_n(sys.argv[2])
    except Exception as e:
        print(f"exception -> ${e}")
    else:
        while True:
            try:
                message = read_message()
            except EOFError:
                break
            else:
                answer = eval_message(message, model_1, model_n)
                write_answer(answer)
