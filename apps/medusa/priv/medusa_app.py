import sys

from message import read_message, write_answer
from medusa_model_1 import medusa_model_1
from medusa_model_n import medusa_model_n


def eval_message(message, model_1, model_n):

    if message == []:
        return []

    ndays_n, ndays_1 = [], []
    [ndays_n.append(x["fe_struct"]) if x["fe_type"] == "ndays_n"
     else ndays_1.append(x["fe_struct"]) for x in message]

    if ndays_1 != []:
        pred1 = model_1.predict(ndays_1)
    else:
        pred1 = []

    if ndays_n != []:
        predn = model_n.predict(ndays_n)
    else:
        predn = []

    return pred1 + predn


if __name__ == "__main__":
    model_1 = medusa_model_1(sys.argv[1])
    model_n = medusa_model_n(sys.argv[2])
    while True:
        message = read_message()
        answer = eval_message(message, model_1, model_n)
        write_answer(answer)
